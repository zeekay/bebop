var wrapper = {
  // Attach to a server and spin up websocket server, serve client.js, etc.
  attach: function(server) {
    // Get reference to current request listener
    var app = server.listeners('request')[0];

    // Remove listener
    if (typeof app === 'function')
      server.removeListener('request', app);

    // Install our middleware, delegate to existing listener
    server.on('request', require('./middleware')(app));

    // Attach websocket server
    var websocket = require('./websocket')(server);

    return {
      app: app,
      server: server,
      websocketServer: websocket.server,
      close: websocket.close,
      send: websocket.send,
    }
  },

  // Attach and reload on file changes
  reload: function(server, dir) {
    if (dir == null) {
      dir = process.cwd()
    }

    var bebop = this.attach(server)

    if (dir) {
      require('./watch')(dir, function(filename) {
        bebop.send({
          type: 'reload',
          filename: filename
        })
      });
    }
    return server;
  }
};

var properties = {};

['client', 'middleware', 'server', 'watch', 'websocket'].forEach(function(property) {
  properties[property] = {
    enumerable: true,
    get: function() {
      return require('./' + property);
    }
  }
});

Object.defineProperties(wrapper, properties);

module.exports = wrapper;
