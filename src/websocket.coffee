WebSocketServer = require('ws').Server

module.exports = (opts = {}) ->
  if typeof opts is 'function'
    server = opts
    opts   = {server: server}

  unless opts.server?
    opts.port ?= 3456

  opts.path ?= '/_bebop'

  wss = new WebSocketServer opts

  clients = {}
  id = 0

  wss.on 'connection', (ws) ->
    id += 1
    ws.id = id
    clients[ws.id] = ws
    ws.on 'close', ->
      delete clients[ws.id]

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

  modified: (filename) ->
    @send
      type: 'modified'
      filename: filename
