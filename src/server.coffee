import basicAuth   from 'basic-auth-connect'
import connect     from 'connect'
import favicons    from 'connect-favicons'
import http        from 'http'
import logger      from 'morgan'
import path        from 'path'
import serveIndex  from 'serve-index'
import serveStatic from 'serve-static'
import url         from 'url'

import log             from './log'
import * as middleware from './middleware'

import {firstAddress} from './utils'

cacheControl = (res, path) ->
  if (serveStatic.mime.lookup path) == 'text/html'
    res.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
    res.setHeader 'Pragma',        'no-cache'

class Server extends http.Server
  constructor: (opts = {}) ->
    opts.host     ?= '0.0.0.0'
    opts.port     ?= 1987
    opts.buildDir ?= process.cwd()
    opts.workDir  ?= process.cwd()
    opts.hideIcon ?= false

    app = connect()

    # Use some helper middleware
    app.use middleware.fakeExpress
    app.use middleware.stripHtml
    app.use middleware.stripSlash

    # Fallback to our favicons
    unless opts.hideIcon?
      app.use favicons __dirname + '/../assets'

    # Log requests
    app.use logger 'dev'

    # Support Basic Auth
    if opts.user and opts.pass
      app.use basicAuth opts.user, opts.pass

    # Install Bebop livereload middleware
    app.use middleware.liveReload()

    # Markdown helper
    app.use middleware.markdown()

    serveOpts =
      # Never want to cache for local development purposes
      cacheControl: false
      setHeaders:   cacheControl

      # Fallthrough and serve directory listings
      fallthrough: true

      # Allow a few options to be customized
      dotfiles:    opts.dotfiles   ? 'deny'
      extensions:  opts.extensions ? ['html', 'htm']
      index:       opts.index      ? ['index.html', 'index.htm']

    # Serve files and indexes from build directory
    app.use serveStatic opts.buildDir, serveOpts
    app.use serveIndex  opts.buildDir, hidden: true

    # Automatically server files from node_modules for easier debugging
    app.use '/node_modules', (serveStatic process.cwd() + '/node_modules', serveOpts)
    app.use middleware.nodeModulesRedirect

    # Also serve content from assets and current working directories. This is
    # useful for serving files referenced by sourcemaps.
    for dir in [opts.assetDir, opts.workDir]
      if dir? and dir != '' and dir != opts.buildDir
        app.use serveStatic dir, serveOpts

    # Redirect 404 pages
    app.use middleware.render404 opts

    # Pass connect app to http.Server
    super app

    # Helpful to save reference
    @app  = app
    @opts = opts

  run: (cb = ->) ->
    {workDir, host, port} = @opts

    @once 'listening', ->
      dir = path.basename workDir
      if host == '0.0.0.0'
        host = firstAddress()
        log.bebop "serving #{dir} at"
        console.log  "    http://#{host}:#{port}" if host?
        console.log  "    http://localhost:#{port}"
      else
        log.bebop "serving #{dir} at http://#{host}:#{port}"

    process.once 'uncaughtException', (err) =>
      if err.code == 'EADDRINUSE'
        log.error 'address in use, retrying...'
        @close()
        @opts.port++
        setTimeout (=> @run()), 1000
      else
        log.error err

    @listen port, host, cb


export default Server
