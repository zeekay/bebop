log          = require '../log'

EventEmitter = require './event-emitter'
dir          = reqiure './dir'
dump         = require './dump'
stacktrace   = require './stacktrace'

{reloadNode, findNode} = require './node'
{root}                 = require './utils'


class Bebop extends EventEmitter
  constructor: (opts) ->
    protocol = opts.protocol ? if location.protocol is 'http:' then 'ws://' else 'wss://'
    hostname = opts.hostname ? location.hostname
    port     = opts.port     ? location.port
    @address = opts.address  ? protocol + hostname + ':' + port + '/_bebop'
    @tries   = 0

  # Called when completion requested.
  handleComplete: (msg) ->
    try
      obj = eval_.call(root, msg)
      @send
        type: 'complete'
        result: dir obj

    catch e
      @send
        type: 'complete'
        result: []

  # Called when eval requested.
  handleEval: (msg) ->
    try
      res = eval_.call(root, msg)
      @send
        type: 'eval'
        result: res

    catch e
      error =
        error: e.message
        stack: stacktrace e

      @send
        type: 'eval'
        result: error

  handleModified: (filename) ->
    if isBrowser
      node = findNode filename
      if node and node._resource.tag.name != 'script'
        reloadNode node
      else
        @reload true

  handleMessage: (message) ->
    message = JSON.parse message.data

    switch message.type
      when 'complete'
        @handleComplete message.name

      when 'eval'
        @handleEval message.code

      when 'modified'
        @handleModified message.filename

      when 'reload'
        @reload()

  connected: ->
    log.info 'connected'
    @tries = 0
    @send
      type: 'connected'
      identifier: @ws.identifier

  # close websocket connection
  close: ->
    log.info 'closed'
    @ws.close()
    @closed = true

  reload: ->
    @close()
    location.reload()

  retry: ->
    return if @closed

    root.setTimeout =>
      @connect()
    , 500

  # WebSockets
  connect: ->
    if @tries > 10
      return log.error 'connection-failed', 'giving up!'

    @tries++

    try
      @ws = new WebSocket @address
    catch err
      return @retry()

    @ws.onopen    = => @connected()
    @ws.onclose   = => @retry()
    @ws.onerror   = => @retry()
    @ws.onmessage = (message) => @handleMessage message

  send: (msg) ->
    @ws.send JSON.stringify msg

Bebop.start = (opts = {}) ->
  root.bebop = bebop = new Bebop opts

  if opts.useRepl
    repl = require 'repl'
    util = require 'util'

    # colorful output
    repl.writer = (obj, showHidden, depth) ->
      util.inspect obj, showHidden, depth, true

    bebop.onopen = ->
      repl.start 'bebop> ', null, null, true

  bebop.connect()

module.exports = Bebop
