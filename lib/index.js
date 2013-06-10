var wrapper = {
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
  }
};

var properties = {};

['client', 'middleware', 'server', 'reload', 'watcher', 'websocket'].forEach(function(property) {
  properties[property] = {
    enumerable: true,
    get: function() {
      return require('./' + property);
    }
  }
});

Object.defineProperties(wrapper, properties);

module.exports = wrapper;
