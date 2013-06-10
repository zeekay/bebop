module.exports = function(server, dir) {
  // Default to current  working directory.
  if (dir == null) {
    dir = process.cwd()
  }

  // Patch ourselves in
  require('./middleware')(server);

  // Handle websocket connections
  var wss = require('./websocket')(server);

  // Watch dir and trigger reload on file changes.
  if (dir) {
    require('./watcher')(dir, function() {
      wss.send({
        type: 'reload'
      })
    });
  }

  return server;
}
