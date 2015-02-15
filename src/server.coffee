{log} = require './utils'

module.exports = createServer: (opts = {}) ->
  opts.host    ?= '0.0.0.0'
  opts.port    ?= 3000
  opts.workDir ?= process.cwd()

  connect = require 'connect'

  app = connect()
  app.use connect.favicon()
  app.use require('./middleware')()
  app.use connect.logger 'dev'

  if opts.user and opts.pass
    app.use connect.basicAuth opts.user, opts.pass

  app.use connect.static opts.workDir
  app.use connect.directory opts.workDir, hidden: true

  server = require('http').createServer app

  server.run = ->
    server.listen opts.port, opts.host, ->
      log.info 'bebop', "listening on #{opts.host}:#{opts.port}"

  server
