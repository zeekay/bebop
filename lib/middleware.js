var fs = require('fs');

function injectJs(res) {
  // Monkey patch res.end to inject our script
  var appendScript = false,
      end          = res.end,
      setHeader    = res.setHeader;

  // Check content-type and increase content-length if we will append
  res.setHeader = function(name, value) {
    if (/text\/html/i.test(value)) {
      appendScript = true;
    } else if (name == 'Content-Length' && appendScript === true) {
      value = parseInt(value, 10) + 35
    }
    setHeader.call(res, name, value);
  }

  // Append script if text/html content-type
  res.end = function(chunk, encoding) {
    if (appendScript) {
      res.write('<script src="/_bebop.js"></script>\n', encoding)
    }
    end.call(res, chunk, encoding)
  }
}

function serveJs(res) {
  res.writeHead(200, {'Content-Type': 'application/javascript'})
  fs.createReadStream(__dirname + '/client.js').pipe(res)
}

module.exports = function(options) {
  if (typeof options === 'function') {
    options = {app: options}
  } else if (options == null) {
    options = {}
  }

  // Serve script from _bebop.js by default
  if (options.url == null) options.url = '/_bebop.js'

  var app   = options.app,
      patch = options.patch,
      url   = options.url;

  // Generic connect compatible middleware to server client code.
  return function(req, res, next) {
    // Serve client-side javascript
    if (req.url === url) return serveJs(res);

    // Inject script into html pages
    if (patch || app) injectJs(res)

    // If we get this far let app handle request
    if (typeof app === 'function') app(req, res)

    // If we are being used as a connect-style middleware call next
    if (typeof next === 'function') next()
  }
}
