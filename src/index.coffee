wrapper =
  # Attach to a server and spin up websocket server, serve static files, etc
  attach: (server, opts = {}) ->
    # attach our middleware
    server = (require './middleware') server

    # Attach websocket server
    websocketServer = (require './websocket') server

    server:          server
    websocketServer: websocketServer

    {close, send} = websocketServer
    {listen}      = server

    close: ->
      close.apply websocketServer, arguments

    send:
      send.apply websocketServer, arguments

    listen: ->
      listen.apply server, arguments

  # Attach and reload on file changes
  reload: (server, dir) ->
    dir = process.cwd() unless dir?
    bebop = @attach(server)
    require('vigil').watch dir, (filename) ->
      bebop.send
        type: 'reload'
        filename: filename
    server

['cli', 'compilers', 'middleware', 'server', 'utils', 'websocket'].forEach (property) ->
  Object.defineProperty wrapper, property,
    enumerable: true
    get: -> require './' + property

module.exports = wrapper
