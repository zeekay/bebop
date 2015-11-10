basicAuth   = require 'basic-auth-connect'
connect     = require 'connect'
favicons    = require 'connect-favicons'
index       = require 'serve-index'
logger      = require 'morgan'
parseUrl    = require 'parseurl'
path        = require 'path'
serveStatic = require 'serve-static'

log        = require './log'
markdown   = require './markdown'
middleware = require './middleware'

module.exports = createServer: (opts = {}) ->
  opts.host      ?= '0.0.0.0'
  opts.port      ?= 1987
  opts.staticDir ?= process.cwd()

  app = connect()

  # Connect no longer parses url for you
  app.use (req, res, next) ->
    req.path = parseUrl(req).pathname
    next()

  app.use favicons __dirname + '/../assets'
  app.use middleware()
  app.use logger 'dev'

  if opts.user and opts.pass
    app.use basicAuth opts.user, opts.pass

  app.use markdown()
  app.use serveStatic opts.staticDir
  app.use index opts.staticDir, hidden: true

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
        throw err

    server.listen opts.port, opts.host, cb

  server
