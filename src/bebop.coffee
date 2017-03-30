import vigil from 'vigil'

import compilers    from './compilers'
import {liveReload} from './middleware'
import server       from './server'
import websocket    from './websocket'


class Bebop
  # Attach to a server and spin up websocket server, serve static files, etc.
  attach: (server, opts = {}) ->

    # attach our middleware
    server = liveReload server

    # Attach websocket server
    websocketServer = websocket server: server

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

  # Attach and reload on file changes.
  reload: (server, dir) ->
    dir = process.cwd() unless dir?
    wss = @attach(server)

    vigil.watch dir, (filename) ->
      wss.send
        type:     'reload'
        filename: filename

    wss

export default Bebop
