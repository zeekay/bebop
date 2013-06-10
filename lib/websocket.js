module.exports = function(server) {
  var WebSocketServer = require('ws').Server,
      wss = new WebSocketServer({server: server, path: '/_bebop'}),
      clients = {},
      id = 0;

  wss.on('connection', function(ws) {
    id += 1;
    ws.id = id;
    clients[ws.id] = ws;

    ws.on('close', function() {
      delete clients[ws.id];
    })
  })

  return {
    server: wss,

    // Close connections
    close: function() {
      for (var id in clients) {
        clients[id].close();
        delete clients[id];
      }
      wss.close()
    },

    // Send message to connections
    send: function(message) {
      for (var id in clients) {
        clients[id].send(JSON.stringify(message))
      }
    }
  }
}
