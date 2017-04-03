import vigil from 'vigil'

import compilers       from './compilers'
import {inject}        from './inject'
import WebSocketServer from './websocket'


class Bebop
  constructor: (@server) ->

  # Attach to a server and spin up websocket server, serve static files, etc.
  attach: (server, opts = {}) ->
    # Attach our middleware
    inject server

    # Attach websocket server
    @wss = new WebSocketServer server: server

  close: ->
    @wss.close.apply @wss, arguments

  send: ->
    @wss.send.apply @wss, arguments

  listen: ->
    @server.listen.apply server, arguments

  # Attach and reload on file changes.
  reload: (server, dir) ->
    dir = process.cwd() unless dir?

    wss = @attach server

    vigil.watch dir, (filename) ->
      @wss.send
        type:     'reload'
        filename: filename

    wss

export default Bebop
