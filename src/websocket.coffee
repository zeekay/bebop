import wsServer from 'ws/lib/websocket-server'


class WebSocketServer
  constructor: (@server, opts = {}) ->
    @clients = {}
    @id      = 0
    @opts    = {}

    # Options for ws.Server
    @opts.path              = opts.path              ? '/_bebop'
    @opts.perMessageDeflate = opts.perMessageDeflate ? false
    @opts.server            = @server

    @server.on 'listening', => @attach()

  attach: ->
    @wss = new wsServer @opts

    @server.once 'close', => @close()

    @wss.on 'connection', (ws) =>
      @id += 1
      ws.id = @id
      @clients[ws.id] = ws
      ws.on 'close', =>
        delete @clients[ws.id]

  # Close connections
  close: ->
    for id of @clients
      @clients[id].close()
      delete @clients[id]
    @wss.close()

  # Send message to connections
  send: (message) ->
    for id of @clients
      try
        @clients[id].send JSON.stringify message
      catch err
        console.error err.stack

  modified: (filename) ->
    @send type: 'modified', filename: filename

export default WebSocketServer
