module.exports = function(server, dir) {
  // Remove request handler
  var handler = server.listeners('request')[0];
  server.removeListener('request', handler);

  // Add our listener
  server.on('request', function(req, res) {
    if (req.url == '/_bebop.js') {
      res.writeHead(200, {'Content-Type': 'application/javascript'})

      var stream = require('fs').createReadStream(__dirname + '/client.js')
      return stream.pipe(res)
    }

    // Monkey patch res.end to inject our script
    var end = res.end,
        setHeader = res.setHeader,
        appendScript = false;

    res.setHeader = function(name, value) {
      if (/text\/html/i.test(value)) {
        appendScript = true;
      } else if (name == 'Content-Length' && appendScript === true) {
        value = parseInt(value, 10) + 35
      }
      setHeader.call(res, name, value);
    }

    res.end = function(chunk, encoding) {
      if (appendScript) {
        res.write('<script src="/_bebop.js"></script>\n', encoding)
      }
      end.call(res, chunk, encoding)
    }

    // call actual request handler
    handler(req, res)
  })

  // Handle websocket connections
  var wss = require('./websocket')(server);

  // Watch dir and trigger reload on file changes.
  require('./watcher')(dir, wss.reload);
  return server;
}
