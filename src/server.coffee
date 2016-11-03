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
{firstAddress} = require './utils'

trailingHtmlRe  = /\.html$/    # Path ends with .html
trailingSlashRe = /\.html\/$/  # Slash erroneously appended to path name

# Connect is fairly minimal, flesh out req, res with a few helper
# methods/properties. Required for compatibility with non-standard connect
# middleware which expects various express conventions.
fakeExpress = (req, res, next) ->
  # Slim stand-ins for what you get with Express
  res.redirect = (loc) ->
    res.writeHead 302, Location: loc
    res.end()

  res.set = (headers) ->
    for k,v of headers
      res.setHeader k, v

  res.send = (body) ->
    res.end body

  # Convenient for our middleware later
  url = url.parse req.url
  req.path   = url.pathname
  req.search = url.search
  next()

# Strip .html from paths for nicer user experience
stripHtml = (req, res, next) ->
  unless trailingHtmlRe.test req.url
    return next()

  loc = req.url.replace /index.html$/, ''
  loc = loc.replace trailingHtmlRe, ''
  res.redirect loc

# Detect odd bug with some browsers and redirect
stripSlash = (req, res, next) ->
  unless trailingSlashRe.test req.url
    return next()
  loc = req.url.replace trailingSlashRe, '.html'
  res.redirect loc

module.exports = createServer: (opts = {}) ->
  opts.host      ?= '0.0.0.0'
  opts.port      ?= 1987
  opts.buildDir  ?= process.cwd()
  opts.workDir   ?= process.cwd()

  app = connect()

  # Use some helper middleware
  app.use fakeExpress
  app.use stripHtml
  app.use stripSlash

  # Fallback to our favicons
  app.use favicons __dirname + '/../assets'

  # Log requests
  app.use logger 'dev'

  # Support Basic Auth
  if opts.user and opts.pass
    app.use basicAuth opts.user, opts.pass

  # Install Bebop middleware
  app.use middleware()

  # Markdown helper
  app.use markdown()

  serveOpts =
    # Never want to cache for local development purposes
    etag:        false

    # Fallthrough and serve directory listings
    fallthrough: true

    # Allow a few options to be customized
    dotfiles:    opts.dotfiles   ? 'deny'
    extensions:  opts.extensions ? ['html', 'htm']
    index:       opts.index      ? ['index.html', 'index.htm']

  # Serve files and indexes from build directory
  app.use serveStatic opts.buildDir, serveOpts
  app.use serveIndex  opts.buildDir, hidden: true

  # Also serve content from assets and current working directories. This is
  # useful for serving files referenced by sourcemaps.
  for dir in [opts.assetDir, opts.workDir]
    if dir? and dir != '' and dir != opts.buildDir
      app.use serveStatic dir, serveOpts

  server = require('http').createServer app
  server.setMaxListeners(100)

  server.on 'listening', ->
    log.bebop "serving #{path.basename opts.workDir} at http://#{opts.host}:#{opts.port}"

  server.run = (cb = ->) ->
    process.once 'uncaughtException', (err) ->
      if err.code == 'EADDRINUSE'
        log.error 'address in use, retrying...'
        server.close()
        opts.port++
        setTimeout server.run, 1000
      else
        log.error err
        process.exit 1

    server.listen opts.port, opts.host, cb

  server
