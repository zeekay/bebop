# inject middleware into connect/express app
export injectConnectApp = (app) ->
  app.stack.splice 2, 0,
    route: ''
    handle: _middleware
  app

# inject middleware into http server
export injectHttpServer = (server) ->
  # Get reference to current request listener
  app = server.listeners('request')[0]

  # Remove listener
  server.removeListener 'request', app if typeof app is 'function'

  # Install our middleware, delegate to existing listener
  server.on 'request', (req, res) ->
    _middleware req, res, ->
      app req, res

# Automatically select the correct middleware to inject
export inject = (app) ->
  if connect().toString() == app.toString()
    injectConnectApp app
  else
    injectHttpServer app
