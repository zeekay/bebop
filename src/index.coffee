wrapper =
  # Attach to a server and spin up websocket server, serve client.js, etc.
  attach: (server) ->
    if require('connect')().toString() == server.toString()
      app = server

      # connect/express app
      app.stack.splice 2, 0,
        route: ''
        handle: require('./middleware') patch: true

      server = require('http').createServer app
      require('./websocket') server
      return server

    # Get reference to current request listener
    app = server.listeners('request')[0]

    # Remove listener
    server.removeListener 'request', app if typeof app is 'function'

    # Install our middleware, delegate to existing listener
    server.on 'request', require('./middleware')(app)

    # Attach websocket server
    websocket = require('./websocket')(server)

    app: app
    server: server
    websocketServer: websocket.server
    close: websocket.close
    send: websocket.send
    listen: ->
      server.listen.apply server, arguments

  # Attach and reload on file changes
  reload: (server, dir) ->
    dir = process.cwd()  unless dir?
    bebop = @attach(server)
    if dir
      require('./watch') dir, (filename) ->
        bebop.send
          type: 'reload'
          filename: filename

    server

properties = {}

['client', 'compilers', 'middleware', 'server', 'watch', 'websocket'].forEach (property) ->
  properties[property] =
    enumerable: true
    get: -> require './' + property

Object.defineProperties wrapper, properties
module.exports = wrapper
