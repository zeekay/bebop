import EventEmitter from './event-emitter'
import WebSocket    from './websocket'
import dir          from './dir'
import dump         from './dump'
import log          from './log'
import stacktrace   from './stacktrace'

import {reloadNode, findNode}      from './node'
import {isBrowser, location, root} from './utils'


class Bebop extends EventEmitter
  constructor: (opts = {}) ->
    super()

    protocol = opts.protocol ? if location.protocol is 'http:' then 'ws://' else 'wss://'
    hostname = opts.hostname ? location.hostname
    port     = opts.port     ? location.port
    @address = opts.address  ? protocol + hostname + ':' + port + '/_bebop'
    @timeout = opts.timeout  ? 1000
    @tries   = 0
    @limit   = -1
    @logger  = log

    @_debug    = opts.debug ? false
    @_failed   = false
    @_retries  = []

    @_once =
      error:  false
      closed: false

    @init opts

  # Default event handlers
  defaultHandlers:
    connected: ->
      log.info 'connected'
      @_once =
        error:  false
        closed: false
      @sendConnected()

    reconnecting: ->
      log.info 'reconnecting'

    closed: ->
      log.info 'closed' unless @_once.closed
      @_once.closed = true

    error: ->
      log.error 'error' unless @_once.error
      @_once.error = true

    message: (message) ->
      log.debug 'message', message
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
      connected:    opts.onconnected
      closed:       opts.onclosed
      error:        opts.onerror
      message:      opts.onmessage
      reconnecting: opts.reconnecting

    # Setup default handlers
    for k,v of @defaultHandlers
      unless handlers[k]?
        handlers[k] = v

    # Bind handlers WebSocket events
    @on 'connect', =>
      if @limit? and @limit >= 0
        if @tries > @limit
          log.error 'Bebop.connect', 'connection-failed: giving up!'
          return @_failed = true
        else
          @tries = @tries + 1

    @on 'connected', (args...) =>
      @tries = 0
      handlers.connected.apply @, args

    @on 'closed', (args...) =>
      handlers.closed.apply @, args

    @on 'error', (args...) =>
      handlers.error.apply @, args

    @on 'message', (args...) =>
      handlers.message.apply @, args

    @on 'reconnecting', =>
      handlers.reconnecting.apply @, args

    Object.defineProperty @, 'debug',
      get: ->
        @_debug
      set: (bool = false) ->
        @_debug = bool
        log.verbose(bool)

    # Set log level
    log.verbose @debug

  # Create new WebSocket connection and connect to it
  connect: ->
    return if @_failed

    @emit 'connecting'

    try
      @ws = new WebSocket @address
    catch err
      log.warn 'Failed to create WebSocket', err
      return @reconnect()

    @ws.onopen = (args...) =>
      @stopRetrying()
      args.unshift 'connected'
      @emit.apply @, args

    @ws.onclose = (args...) =>
      args.unshift 'closed'
      @emit.apply @, args

    @ws.onerror = (args...) =>
      args.unshift 'error'
      @emit.apply @, args

    @ws.onmessage = (e) =>
      @emit 'message', JSON.parse e.data

    if isBrowser
      root.addEventListener 'beforeunload', => @ws.close()

  # Retry connection on failure/timeout
  reconnect: ->
    return if @_failed

    @emit 'reconnecting'

    @_retries.push root.setTimeout =>
      @connect()
    , @timeout

  stopRetrying: ->
    @tries = 0
    clearTimeout t for t in @_retries
    @_retries = []

  # Close WebSocket connection
  close: ->
    @ws.close()

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
    root.location?.reload()

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

export default Bebop
