fs = require 'fs'

bebopInclude = '<script src="/bebop-client/bebop.js"></script>\n'

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
      value = parseInt(value, 10) + bebopInclude.length
    setHeader.call res, name, value
  # Append script if text/html content-type
  res.end = (chunk, encoding) ->
    if appendScript
      res.write bebopInclude, encoding
    end.call res, chunk, encoding

# serve static js, map, coffee source files
serveStatic = (req, res) ->
  switch req.url
    when '/bebop-client/bebop.js'
      headers =
        'Content-Type': 'application/javascript'
        'SourceMap':    'bebop.map'
        'X-SourceMap':  'bebop.map'

    when '/bebop-client/bebop.map'
      headers =
        'Content-Type': 'application/json'

    when '/bebop-client/bebop.coffee'
      headers =
        'Content-Type': 'application/coffeescript'

  res.writeHead 200, headers
  fs.createReadStream(__dirname + '/..' + req.url).pipe res

module.exports = (options) ->
  if typeof options is 'function'
    options = app: options
  else options = {} unless options?

  # Serve script from _bebop.js by default
  app = options.app

  # Generic connect compatible middleware to server client code.
  middleware = (req, res, next) ->
    # Serve static files
    return (serveStatic req, res) if /^\/bebop-client/.test req.url

    # Inject script into html pages
    injectJs res

    # If we get this far let app handle request
    app req, res if typeof app is 'function'

    # If we are being used as a connect-style middleware call next
    next() if typeof next is 'function'

  `function bebop(req, res, next) { return middleware(req, res, next); };`
