fs = require 'fs'

injectJs = (res) ->
  # Monkey patch res.end to inject our script
  appendScript = false
  end = res.end
  setHeader = res.setHeader

  # Check content-type and increase content-length if we will append
  res.setHeader = (name, value) ->
    if /text\/html/i.test(value)
      appendScript = true
    else if name is 'Content-Length' and appendScript
      value = parseInt(value, 10) + 34
    setHeader.call res, name, value

  # Append script if text/html content-type
  res.end = (chunk, encoding) ->
    if appendScript
      res.write '<script src="/_bebop.js"></script>\n', encoding
    end.call res, chunk, encoding

serveJs = (res) ->
  res.writeHead 200,
    'Content-Type': 'application/javascript'
  fs.createReadStream(__dirname + '/client.js').pipe res

module.exports = (options) ->
  if typeof options is 'function'
    options = app: options
  else options = {} unless options?

  # Serve script from _bebop.js by default
  options.url = '/_bebop.js'  unless options.url?
  app = options.app
  patch = options.patch
  url = options.url

  # Generic connect compatible middleware to server client code.
  (req, res, next) ->

    # Serve client-side javascript
    return serveJs res  if req.url is url

    # Inject script into html pages
    injectJs res if patch or app

    # If we get this far let app handle request
    app req, res if typeof app is 'function'

    # If we are being used as a connect-style middleware call next
    next() if typeof next is 'function'
