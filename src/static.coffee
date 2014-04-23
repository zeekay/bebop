connect    = require 'connect'
http       = require 'http'
middleware = require './middleware'


class StaticServer
  constructor: (opts = {}) ->
    @host = opts.host ? '0.0.0.0'
    @port = opts.port ? 3000

    @dir  = opts.dir  ? process.cwd()

    @app = connect()
    @app.use connect.favicon()
    @app.use middleware()
    @app.use connect.logger 'dev'

    if opts.user and opts.pass
      @app.use connect.basicAuth opts.user, opts.pass

    @app.use connect.static @dir
    @app.use connect.directory @dir, hidden: true

    @server = http.createServer @app

  run: (cb) ->
    @server.listen @port, @host, cb


module.exports =
  StaticServer: StaticServer
