ws = require 'ws'


class WebSocketServer
  defaultPort: 1987
  defaultPath: '/ws'

  constructor: (opts = {}) ->
    unless opts.server?
      opts.port ?= @defaultPort

    opts.path ?= @defaultPath

    @wss = new ws.Server opts

    clients = {}
    id = 0

    @wss.on 'connection', (ws) ->
      id += 1
      ws.id = id
      clients[ws.id] = ws
      ws.on 'close', ->
        delete clients[ws.id]

  # Close connections
  close: ->
    for id of clients
      clients[id].close()
      delete clients[id]
    @wss.close()

  # Send message to connections
  send: (message) ->
    for id of clients
      try
        clients[id].send JSON.stringify message
      catch err
        console.error err.stack


class BebopClientServer extends WebSocketServer
  defaultPort: 1988

  defaultPath: '/bebop-client/ws'

  modified: (filename) ->
    @send
      type: 'modified'
      filename: filename


class BebopControlServer extends WebSocketServer
  defaultPort: 1989

  defaultPath: '/bebop-control/ws'




module.exports =
  WebsocketServer:    WebsocketServer
  BebopClientServer:  BebopClientServer
  BebopControlServer: BebopControlServer
