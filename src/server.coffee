basicAuth   = require 'basic-auth-connect'
connect     = require 'connect'
favicons    = require 'connect-favicons'
logger      = require 'morgan'
path        = require 'path'
serveIndex  = require 'serve-index'
serveStatic = require 'serve-static'
url         = require 'url'

log        = require './log'
markdown   = require './markdown'
middleware = require './middleware'

module.exports = createServer: (opts = {}) ->
  opts.host      ?= '0.0.0.0'
  opts.port      ?= 1987
  opts.staticDir ?= process.cwd()
  opts.fallback   = '/' + (opts.fallback ? '').replace /^[./]+/, ''

  app = connect()

  # Connect no longer parses url for you
  app.use (req, res, next) ->
    url = url.parse req.url
    req.path   = url.pathname
    req.search = url.search
    req.set = (headers) ->
      for k,v of headers
        res.setHeader k, v
    next()

  app.use favicons __dirname + '/../assets'
  app.use logger 'dev'

  if opts.user and opts.pass
    app.use basicAuth opts.user, opts.pass

  app.use middleware()
  app.use markdown()

  serve = serveStatic opts.staticDir,
    dotfiles:    'deny'
    etag:        false
    extensions:  ['html', 'htm']
    fallthrough: true
    index:       ['index.html', 'index.htm']

  app.use serve
  app.use serveIndex opts.staticDir, hidden: true

  app.use (req, res, next) ->
    ext = path.extname req.path

    return next() unless opts.fallback
    return next() unless (ext is '') or /\.html?/.test ext

    # Update URL to match fallback
    req.url = opts.fallback + (req.search ? '')

    # Force URL to get parsed again
    delete req._parsedUrl
    delete req._parsedOriginalUrl

    # Try and serve fallback
    serve req, res, next

  server = require('http').createServer app

  server.setMaxListeners(100)

  server.on 'listening', ->
    cwd = process.cwd()
    dir = path.basename cwd
    log.bebop "serving #{dir} at http://#{opts.host}:#{opts.port}"

  server.run = (cb = ->) ->
    process.once 'uncaughtException', (err) ->
      if err.code == 'EADDRINUSE'
        log.error 'address in use, retrying...'
        server.close()
        opts.port++
        setTimeout server.run, 1000
      else
        console.log err
        console.log err.stack
        process.exit 1

    server.listen opts.port, opts.host, cb

  server
