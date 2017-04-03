import exec  from 'executive'
import fs    from 'fs'
import os    from 'os'
import vigil from 'vigil'

import Server           from './server'
import WebSocketServer  from './websocket'
import compilers        from './compilers'
import log              from './log'
import {defaultExclude} from './utils'
import {version}        from '../package.json'

error = (message) ->
  log.error message
  process.exit 1

version_ = ->
  console.log version
  process.exit 0

usage = ->
  console.log """
  bebop <command> [options] [file]

  Commands:
    compile|c  Compile files and exit
    help       Display this message
    version    Display version

  Options:
    --auto                      Automatically compile even without a local config file
    --compilers <ext:compiler>  Specify compiler to use for a given extension
    --config <file>             Specify bebop.coffee to use
    --exclude, -x <file>        Exclude files from watching, compiling
    --force-reload              Force reload when file is compiled
    --host, -h <hostname>       Hostname to bind to
    --include, -i <file>        Include files for watching, compiling
    --no-server                 Do not run static file server
    --no-watch                  Do not watch files for changes
    --open, -o                  Open browser automatically
    --port, -p <port>           Port to listen on
    --pre <cmd>                 Command to execute first
    --secure, -s <user:pass>    Require authentication
    --asset-dir <path>          Directory used as root for compiling, watching
    --build-dir <path>          Directory used as root for static file server
    --work-dir  <path>          Directory used as root for process
    --index <file>              Index file to attempt to serve when directory requested
    --hide-icon                 Hide Bebop's favicon
  """
  process.exit 0

try
  require 'coffee-script/register'
catch err

cwd = process.cwd()

confs = [
  process.env.HOME + '/.bebop'
  cwd + '/.bebop'
  cwd + '/bebop'
]

opts =
  compile:        false
  compileOnly:    false
  compilers:      {}
  defaultExclude: true
  exclude:        []
  fallback:       null
  forceReload:    false
  host:           '0.0.0.0'
  include:        []
  index:          ['index.html', 'index.htm']
  initialPath:    ''
  port:           null
  pre:            (done) -> done()
  runServer:      true
  watch:          true
  assetDir:       cwd
  buildDir:       cwd
  workDir:        cwd
  hideIcon:       false

# require config file and override opts
requireConfig = (path) ->
  try
    conf = require.resolve path
  catch err
    return

  if fs.existsSync conf
    for k,v of require conf
      opts[k] = v
    opts.compile = true # Compile if config file is found

# allow user to override defaults
for conf in confs
  requireConfig conf

args = process.argv.slice 2

while opt = args.shift()
  switch opt
    # commands
    when 'compile', 'c', '--compile', '-c'
      opts.compileOnly = true
    when 'help', '--help'
      usage()
    when 'version', '--version', '-v'
      version_()

    # options
    when '--config'
      requireConfig args.shift()
    when '--open', '-o'
      opts.open = true
    when '--no-server'
      opts.runServer = false
    when '--no-watch'
      opts.watch = false
    when '--auto'
      opts.compile = true
    when '--include', '-i'
      opts.include.push args.shift()
    when '--exclude', '-x'
      opts.exclude.push args.shift()
    when '--no-default-exclude'
      opts.defaultExclude = false
    when '--force-reload'
      opts.forceReload = true
    when '--fallback'
      opts.fallback = args.shift()
    when '--host', '-h'
      opts.host = args.shift()
    when '--pre'
      cmd = args.shift()
      opts.pre = (done) -> exec cmd, done
    when '--port', '-p'
      p = args.shift()
      error 'missing port' unless p
      opts.port = parseInt p, 10
    when '--secure', '-s'
      credentials = args.shift()
      if credentials
        [opts.user, opts.pass] = credentials.split(':')
      else
        opts.user = 'bebop'
        opts.pass = 'beepboop'
    when '--asset-dir'
      opts.assetDir = args.shift()
    when '--build-dir'
      opts.buildDir = args.shift()
    when '--work-dir'
      opts.workDir = args.shift()
    when '--compilers', '-c'
      for compiler in args.shift().split ','
        [ext, mod] = compiler.split ':'
        opts.compilers[ext] = mod
    when '--hide-icon'
      opts.hideIcon = true
    else
      if opt.charAt(0) is '-'
        error "Unrecognized option: '#{opt}'"
      else
        opts.initialPath = opt

# Setup include/expludes
if opts.defaultExclude
  opts.exclude = [vigil.utils.excludeRe, defaultExclude].concat opts.exclude

# Options for vigil watch/walk
vigilOpts =
  exclude: opts.exclude
  include: opts.include
  patch:   false

# Setup any custom preprocessors
for ext, compiler of opts.compilers
  if typeof compiler is 'string'
    try
      bits = compiler.split '.'
      compiler = require bits.shift()

      while bits.length
        compiler = compiler[bits.shift()]

      compilers[ext] = compiler
    catch err
      console.log err
  else
    # expected to be a function
    compilers[ext] = compiler

# Filename path relative to current working dir
relativeName = (filename) ->
  filename.replace opts.workDir + '/', ''

# Compile modified file
compile = (filename, cb = ->) ->
  compilers.compile filename, opts, (err, compiled) ->
    filename = relativeName filename

    if err?
      log.error "failed to compile #{filename}", err
      return

    log.compiled filename if compiled

    cb null, compiled

# Let's bop!
opts.pre (err) ->
  return console.error err if err?

  # Do initial compile
  if opts.compile
    vigil.walk opts.workDir, vigilOpts, (filename) ->
      compile filename if opts.compile

  if opts.compileOnly
    return

  if opts.runServer
    app       = new Server opts
    websocket = new WebSocketServer server: app
  else
    app       = run: ->
    websocket = modified: ->

  if opts.watch
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
  app.run ->
    if opts.open or opts.initialPath != ''
      switch os.platform()
        when 'darwin'
          exec "open http://#{opts.host}:#{opts.port}/#{opts.initialPath}"
        when 'linux'
          exec "xdg-open http://#{opts.host}:#{opts.port}/#{opts.initialPath}"
