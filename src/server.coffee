path     = require 'path'
markdown = require './markdown'

log = require './log'

module.exports = createServer: (opts = {}) ->
  opts.host      ?= '0.0.0.0'
  opts.port      ?= 1987
  opts.staticDir ?= process.cwd()

  connect = require 'connect'

  app = connect()
  app.use connect.favicon()
  app.use require('./middleware')()
  app.use connect.logger 'dev'

  if opts.user and opts.pass
    app.use connect.basicAuth opts.user, opts.pass

  app.use markdown()
  app.use connect.static opts.staticDir
  app.use connect.directory opts.staticDir, hidden: true

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
        throw new err

    server.listen opts.port, opts.host, cb

  server
