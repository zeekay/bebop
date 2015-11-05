wrapper =
  # Attach to a server and spin up websocket server, serve static files, etc
  attach: (server, opts = {}) ->
    # attach our middleware
    server = (require './middleware') server

    # Attach websocket server
    websocketServer = (require './websocket') server: server

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

Object.defineProperties wrapper,
  compilers:  enumerable: true, get: -> require './compilers'
  middleware: enumerable: true, get: -> require './middleware'
  server:     enumerable: true, get: -> require './server'
  utils:      enumerable: true, get: -> require './utils'
  websocket:  enumerable: true, get: -> require './websocket'

module.exports = wrapper
