import os         from 'os'

import findCoffee from 'find-coffee'
import isFunction from 'es-is/function'
import isString   from 'es-is/string'
import vigil      from 'vigil'

import Server           from './server'
import WebSocketServer  from './websocket'
import compilers        from './compilers'
import log              from './log'
import {defaultExclude} from './utils'
import {inject}         from './inject'


class Bebop
  constructor: (@opts = {}) ->
    @opts.cwd            ?= process.cwd()
    @opts.defaultExclude ?= true

    if @opts.defaultExclude
      @opts.exclude = [vigil.utils.excludeRe, defaultExclude].concat @opts.exclude

    # Setup default opts for vigil
    @vigilOpts =
      exclude: @opts.exclude
      include: @opts.include
      patch:   @opts.vigil?.patch == false

    @compilers = Object.assign {}, compilers

    for ext, compiler of @opts.compilers
      @addCompiler ext, compiler

    @loadConfig()

  # Add compiler for a given extension
  addCompiler: (ext, compiler) ->
    if isString compiler
      try
        bits = compiler.split '.'
        compiler = require bits.shift()

        while bits.length
          compiler = compiler[bits.shift()]

        @compilers[ext] = compiler
      catch err
        console.error err.stack
    else if isFunction compiler
      # expected to be a function
      @compilers[ext] = compiler
    else
      throw new Error "Not a valid compiler: #{compiler}"

  # Find and require configuration overrides
  loadConfig: ->
    requireConfig = (path) ->
      try
        require.resolve path
      catch err
        try
          require.resolve path + '.coffee'
          findCoffee 2
        catch err
        return

    load = (path) =>
      conf = requireConfig path
      return unless conf

      if fs.existsSync conf
        for k,v of require conf
          @opts[k] = v

        # TODO: Come up with better heuristic to detect if we should compile
        @opts.compile = true

    confs = [
      process.env.HOME + '/.bebop'
      @opts.cwd + '/.bebop'
      @opts.cwd + '/bebop'
    ]

    # allow user to override defaults
    for conf in confs
      load conf

  # Return path relative to current working dir
  relativeName: (filename) ->
    filename.replace @opts.workDir + '/', ''

  # Compile modified file
  compile: (filename, cb = ->) ->
    @compilers.compile filename, @opts, (err, compiled) ->
      filename = @relativeName filename

      if err?
        log.error "failed to compile #{filename}", err
        return

      log.compiled filename if compiled

      cb null, compiled

  # Compile everything
  compileAll: ->
    @walk (filename) =>
      @compile filename

  # Walk work dir, calling callback
  walk: (cb) ->
    unless isFunction cb
      throw new Error "Expected callback to walk to be a function, got: #{cb}"

    vigil.walk @opts.workDir, @vigilOpts, cb

  # Watch asset dir and recompile on changes
  watch: ->
    vigil.watch @opts.assetDir, @vigilOpts, (filename) =>
      unless @opts.compile
        log.modified filename
        return @websocket.modified filename

      @compile filename, (err, compiled) =>
        unless compiled
          log.modified filename
          @websocket.modified filename
        else
          if @opts.forceReload
            @websocket.modified filename

    # Watch build dir and reload on changes
    if @opts.buildDir != @opts.assetDir
      vigil.watch @opts.buildDir, @vigilOpts, (filename) =>
        log.modified filename
        return #websocket.modified filename

  # Start server
  run: (cb = ->) ->
    @server.run (err) =>
      throw err if err?

      if @opts.open or @opts.initialPath != ''
        switch os.platform()
          when 'darwin'
            exec "open http://#{opts.host}:#{opts.port}/#{opts.initialPath}"
          when 'linux'
            exec "xdg-open http://#{opts.host}:#{opts.port}/#{opts.initialPath}"
      cb()

export default Bebop
