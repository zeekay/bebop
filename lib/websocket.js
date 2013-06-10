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

  process.on('message', function(message) {
    if (message && message.type && message.type == 'stop') {
      for (var id in clients) {
        clients[id].close();
      }
    }
  })

  function reload() {
    for (var id in clients) {
      clients[id].send(JSON.stringify({evt: 'reload'}))
    }
  }

  return {
    reload: reload
  }
}
