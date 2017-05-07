import findCoffee from 'find-coffee'
import vigil      from 'vigil'

import Server           from './server'
import WebSocketServer  from './websocket'
import compilers        from './compilers'
import {defaultExclude} from './utils'
import {inject}         from './inject'

# # Setup include/expludes
# if opts.defaultExclude
#   opts.exclude = [vigil.utils.excludeRe, defaultExclude].concat opts.exclude

# # Options for vigil watch/walk
# vigilOpts =
#   exclude: opts.exclude
#   include: opts.include
#   patch:   false

# # Setup any custom preprocessors
# for ext, compiler of opts.compilers
#   if typeof compiler is 'string'
#     try
#       bits = compiler.split '.'
#       compiler = require bits.shift()

#       while bits.length
#         compiler = compiler[bits.shift()]

#       compilers[ext] = compiler
#     catch err
#       console.log err
#   else
#     # expected to be a function
#     compilers[ext] = compiler

# # Do initial compile
# if opts.compile
#   vigil.walk opts.workDir, vigilOpts, (filename) ->
#     compile filename

class Bebop
  constructor: (@opts) ->
    @opts.cwd ?= process.cwd()

  # Require config file and override opts
  requireConfig: (path) ->
    findCoffee()

    try
      conf = require.resolve path
    catch err
      return

    if fs.existsSync conf
      for k,v of require conf
        @opts[k] = v

      # TODO: Come up with better heuristic to detect if we should compile
      @opts.compile = true

  # Read config
  readConfig: ->
    confs = [
      process.env.HOME + '/.bebop'
      @opts.cwd + '/.bebop'
      @opts.cwd + '/bebop'
    ]

    # allow user to override defaults
    for conf in confs
      @requireConfig conf

  # Filename path relative to current working dir
  relativeName: (filename) ->
    filename.replace @opts.workDir + '/', ''

  # Compile modified file
  compile: (filename, cb = ->) ->
    compilers.compile filename, opts, (err, compiled) ->
      filename = @relativeName filename

      if err?
        log.error "failed to compile #{filename}", err
        return

      log.compiled filename if compiled

      cb null, compiled

  watch: ->
    # Watch asset dir and recompile on changes
    vigil.watch opts.assetDir, vigilOpts, (filename) ->
      unless opts.compile
        log.modified filename
        return websocket.modified filename

      compile filename, (err, compiled) ->
        unless compiled
          log.modified filename
          websocket.modified filename
        else
          if opts.forceReload
            websocket.modified filename

    # Watch build dir and reload on changes
    if opts.buildDir != opts.assetDir
      vigil.watch opts.buildDir, vigilOpts, (filename) ->
        log.modified filename
        return websocket.modified filename

  # Start server
  run: ->
    @server    = new Server opts
    # websocket = new WebSocketServer server, opts
    @websocket = modified: ->

    @server.run =>
      if @opts.open or @opts.initialPath != ''
        switch os.platform()
          when 'darwin'
            exec "open http://#{opts.host}:#{opts.port}/#{opts.initialPath}"
          when 'linux'
            exec "xdg-open http://#{opts.host}:#{opts.port}/#{opts.initialPath}"

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
