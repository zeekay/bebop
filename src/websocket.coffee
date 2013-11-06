module.exports = (server) ->
  WebSocketServer = require('ws').Server

  wss = new WebSocketServer
    server: server
    path: '/_bebop'

  clients = {}
  id = 0

  wss.on 'connection', (ws) ->
    id += 1
    ws.id = id
    clients[ws.id] = ws
    ws.on 'close', ->
      delete clients[ws.id]

  websocket =
    server: wss

    # Close connections
    close: ->
      for id of clients
        clients[id].close()
        delete clients[id]
      wss.close()


    # Send message to connections
    send: (message) ->
      for id of clients
        try
          clients[id].send JSON.stringify message
        catch err
          console.error err.stack

  process.on 'exit', ->
    websocket.send
      type: 'reload'

  websocket
