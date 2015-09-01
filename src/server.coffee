path     = require 'path'
markdown = require './markdown'

{log} = require './utils'

module.exports = createServer: (opts = {}) ->
  opts.host      ?= '0.0.0.0'
  opts.port      ?= 3000
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

  server.run = ->
    server.listen opts.port, opts.host, ->
      cwd = process.cwd()
      dir = path.basename cwd
      log.info 'bebop', "serving #{dir} at http://#{opts.host}:#{opts.port}"

  server
