{log} = require './utils'

module.exports = createServer: (opts = {}) ->
  opts.host ?= '0.0.0.0'
  opts.port ?= 3000

  connect = require 'connect'

  app = connect()
  app.use connect.favicon()
  app.use connect.logger 'dev'
  app.use require('./middleware')
    patch: true

  if opts.user and opts.pass
    app.use connect.basicAuth opts.user, opts.pass

  app.use connect.static process.cwd()
  app.use connect.directory process.cwd(), hidden: true

  server = require('http').createServer app

  server.run = ->
    server.listen opts.port, opts.host, ->
      log "bebop\x1B[0m listening on #{opts.host}:#{opts.port}"

  server
