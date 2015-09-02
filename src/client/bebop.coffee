EventEmitter = require './event-emitter'
dir          = require './dir'
dump         = require './dump'
log          = require './log'
stacktrace   = require './stacktrace'

{reloadNode, findNode} = require './node'
{root}                 = require './utils'


class Bebop extends EventEmitter
  constructor: (opts = {}) ->
    super

    protocol = opts.protocol ? if location.protocol is 'http:' then 'ws://' else 'wss://'
    hostname = opts.hostname ? location.hostname
    port     = opts.port     ? location.port
    @address = opts.address  ? protocol + hostname + ':' + port + '/_bebop'
    @timeout = opts.timeout  ? 500
    @debug   = opts.debug ? false
    @tries   = 0

    @init opts

  # Default event handlers
  defaultHandlers:
    close:     (e)       -> @close e
    connected: (e)       -> @sendConnected e
    error:     (err)     -> @reconnect err
    message:   (message) ->
      switch message.type
        when 'complete'
          @sendComplete message.name
        when 'eval'
          @sendEval message.code
        when 'modified'
          @modified message.filename
        when 'reload'
          @reload()
        else
          log.warn "Unknown message type '#{message.type}'", message

  # Initialize Bebop
  init: (opts = {}) ->
    # Allow user to override default handlers
    handlers =
      connected: opts.onconnected
      close:     opts.onclose
      error:     opts.onerror
      message:   opts.onmessage

    # Setup default handlers
    for k,v of @defaultHandlers
      unless handlers[k]?
        handlers[k] = v

    # Bind handlers WebSocket events
    @on 'connect', (tries)   =>
      if @limit? and @limit > 0
        if tries > @limit
          log.error 'connection-failed', 'giving up!'
          return @closed = true
        else
          @tries += 1

    @on 'connected', (e) =>
      log 'connected', e
      @tries = 0
      handlers.connected.call @, e

    @on 'close', (e) =>
      log 'close', e
      @closed = true
      handlers.close.call @, e

    @on 'error',   (err)     =>
      log 'error', err
      handlers.error.call   @, err

    @on 'message', (message) =>
      log 'message', message
      handlers.message.call @, message

  # Create new WebSocket connection and connect to it
  connect: ->
    @emit 'connect', @tries
    return if @closed

    try
      @ws = new WebSocket @address
    catch err
      return @reconnect()

    @ws.onopen    = (e) => @emit 'connected', e
    @ws.onclose   = (e) => @emit 'close',     e
    @ws.onerror   = (e) => @emit 'error',     e.data
    @ws.onmessage = (e) => @emit 'message',   JSON.parse e.data

  # Retry connection on failure/timeout
  reconnect: ->
    @emit 'reconnect'
    return if @closed

    root.setTimeout =>
      @connect()
    , @timeout

  # Close WebSocket connection
  close: ->
    @emit 'closed'
    @ws.close()
    @closed = true

  # Send WebSocket message
  send: (msg) ->
    @emit 'send', msg
    @ws.send JSON.stringify msg

  # Return completions for code fragment
  complete: (code) ->
    @emit 'complete', code

    try
      dir (eval_.call root, code)
    catch e
      []

  # Called when eval requested.
  eval: (code) ->
    @emit 'eval', code

    try
      res = eval_.call root, msg
    catch e
      error =
        error: e.message
        stack: stacktrace e

  modified: (filename) ->
    @emit 'modified', filename

    if isBrowser
      node = findNode filename
      if node and node._resource.tag.name != 'script'
        reloadNode node
      else
        @reload true

  # Close connection and reload current page
  reload: ->
    @emit 'reload'
    @close()
    location.reload()

  # Client responses to server RPC calls
  sendConnected: ->
    @send
      type: 'connected'
      identifier: @ws.identifier

  # Return completions
  sendComplete: (code) ->
    @send
      type: 'complete'
      result: @complete code

  # Called when eval requested.
  sendEval: (code) ->
    @send
      type:   'eval'
      result: @eval code

module.exports = Bebop
