{log} = require './utils'

module.exports = createServer: (opts) ->
  connect = require 'connect'

  app = connect()
  app.use connect.logger 'dev'
  app.use require('./middleware')
    patch: true

  if opts.user and opts.pass
    app.use connect.basicAuth opts.user, opts.pass

  app.use connect.static process.cwd()
  app.use connect.directory process.cwd(), hidden: true

  server = require('http').createServer app

  server.run = ->
    server.listen 3000, '0.0.0.0', ->
      log 'bebop listening on 0.0.0.0:3000'

  server
