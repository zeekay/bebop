fs   = require 'fs'
path = require 'path'

# Generic connect compatible middleware to server client code.
# Wrapped with a named function for easier debugging.
middleware = (opts = {}) ->
  bebopJs = """
            <script src="/bebop.min.js"></script>
            <script>
              var bebop = new Bebop(#{JSON.stringify opts});
              bebop.debug = true;
              bebop.connect();
            </script>
            """

  # Monkey patch res.end to inject our script
  injectJs = (res) ->
    appendScript = false
    end = res.end
    setHeader = res.setHeader

    # Check content-type and increase content-length if we will append
    res.setHeader = (name, value) ->
      if /text\/html/i.test(value)
        appendScript = true
      else if name is 'Content-Length' and appendScript
        value = parseInt(value, 10) + bebopJs.length
      setHeader.call res, name, value

    # Append script if text/html content-type
    res.end = (chunk, encoding) ->
      if appendScript
        res.write bebopJs, encoding
      end.call res, chunk, encoding

  # serve static js, map, coffee source files
  serveStatic = (req, res) ->
    if /\.js$/.test req.url
      contentType = 'application/javascript'
    else if /\.coffee$/.test req.url
      contentType = 'application/coffeescript'
    else
      contentType = 'text/html'

    headers =
      'Content-Type': contentType

    if /^\/src\/node_modules/.test req.url
      req.url = req.url.substring 4

    file = path.join __dirname, '/..', req.url

    res.writeHead 200, headers
    fs.createReadStream(file).pipe res

  _middleware = (req, res, next) ->
    # Serve static files
    if /^\/bebop|src\/client\/bebop/.test req.url
      return serveStatic req, res

    # Inject script into html pages
    injectJs res

    next()

  `function bebop(req, res, next) { return _middleware(req, res, next); };`

module.exports = (opts = {}) ->
  if typeof opts is 'function'
    opts = {attach: opts}

  _middleware = middleware opts

  # inject middleware into connect/express app
  injectConnectApp = (app) ->
    app.stack.splice 2, 0,
      route: ''
      handle: _middleware
    app

  # inject middleware into http server
  injectHttpServer = (server) ->
    # Get reference to current request listener
    app = server.listeners('request')[0]

    # Remove listener
    server.removeListener 'request', app if typeof app is 'function'

    # Install our middleware, delegate to existing listener
    server.on 'request', (req, res) ->
      _middleware req, res, ->
        app req, res

  # inject our middleware
  inject = (app) ->
    if require('connect')().toString() == app.toString()
      injectConnectApp app
    else
      injectHttpServer app

  return inject opts.attach if opts.attach?

  # used directly as middleware
  _middleware
