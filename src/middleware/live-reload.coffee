import connect from 'connect'
import fs      from 'fs'
import path    from 'path'


# Middleware to serve associated bebop client files
serveStatic = (req, res, next) ->
  switch path.extname req.url
    when '.js'
      contentType = 'application/javascript'
    when '.coffee'
      contentType = 'application/coffeescript'
    when '.map'
      contentType = 'application/json'
    else
      next()

  # Get path to file
  if /^\/src\/node_modules/.test req.url
    req.url = req.url.substring 4
  file = path.join __dirname, '/..', req.url

  # Serve static file
  res.writeHead 200, 'Content-Type': contentType
  fs.createReadStream(file).pipe res


# Live Reload middleware constructor
class LiveReload
  constructor: (opts = {}) ->
    @js = """
      <script src="/bebop.min.js"></script>
      <script>
        var bebop = new Bebop(#{JSON.stringify opts});
        bebop.debug = true;
        bebop.connect();
      </script>
      """

  # Monkey patch res.end to inject our script
  injectJs: (res) ->
    appendScript = false
    end          = res.end
    setHeader    = res.setHeader

    # Check content-type and increase content-length if we will append
    res.setHeader = (name, value) ->
      if /text\/html/i.test(value)
        appendScript = true
      else if name is 'Content-Length' and appendScript
        value = parseInt(value, 10) + @js.length
      setHeader.call res, name, value

    # Append script if text/html content-type
    res.end = (chunk, encoding) ->
      if appendScript
        res.write @js, encoding
      end.call res, chunk, encoding

  middleware: (req, res, next) ->
    # Serve static files
    if /^\/bebop|src\/client\/bebop/.test req.url
      return @serveStatic req, res, next

    # Inject script into html pages
    @injectJs res

    next()

# Generic connect compatible middleware to server client code.
export default livereload = (opts = {}) ->
  liveReload = new LiveReload opts

  # Wrap with a named function for easier debugging.
  `function liveReload(req, res, next) { return liveReload.middleware(req, res, next); };`
