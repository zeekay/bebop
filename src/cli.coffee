exec = require 'executive'
fs   = require 'fs'
os   = require 'os'

compilers = require './compilers'
server    = require './server'
{log}     = require './utils'

error = (message) ->
  console.error message
  process.exit 1

usage = ->
  console.log """
  bebop [options]

  Options:
    --config, -c    Specify bebop.coffee to use
    --compilers,    Specify compiler to use for a given extension
    --force-compile Compile files and exit
    --host, -h      Hostname to bind to
    --no-compile    Do not compile files automatically
    --no-watch      Do not watch files for changes
    --no-server     Do not run static file server
    --open, -o      Open browser automatically
    --port, -p      Port to listen on
    --secure, -s    Require authentication
  """
  process.exit 0

require.extensions['.coffee'] = ->
  require 'coffee-script'
  require.extensions['.coffee'].apply require.extensions, arguments

cwd = process.cwd()

confs = [
  process.env.HOME + '/.bebop'
  cwd + '/.bebop'
  cwd + '/bebop'
]

opts =
  compile:   true
  host:      'localhost'
  port:      1987
  watch:     true
  compilers: {}
  runServer: true

# require config file and override opts
requireConfig = (path) ->
  try
    conf = require.resolve conf
  catch err
    continue

  if fs.existsSync conf
    for k,v of require conf
      opts[k] = v

# allow user to override defaults
for conf in confs
  requireConfig conf

args = process.argv.slice 2

while opt = args.shift()
  switch opt
    when '--help', '-v'
      usage()
    when '--config', '-c'
      requireConfig args.shift()
    when '--open', '-o'
      opts.open = true
    when '--no-server'
      opts.runServer = false
    when '--no-watch'
      opts.watch = false
    when '--no-compile'
      opts.compile = false
    when '--force-compile'
      opts.forceCompile = true
    when '--host', '-h'
      opts.host = args.shift()
    when '--port', '-p'
      opts.port = parseInt args.shift(), 10
    when '--secure', '-s'
      credentials = args.shift()
      if credentials
        [opts.user, opts.pass] = credentials.split(':')
      else
        opts.user = 'bebop'
        opts.pass = 'beepboop'
    when '--compilers', '-c'
      for compiler in args.shift().split ','
        [ext, mod] = compiler.split ':'
        opts.compilers[ext] = mod
    else
      error 'Unrecognized option' if opt.charAt(0) is '-'

# setup any custom preprocessors
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

# compile files
compile = (filename, cb = ->) ->
  compilers.compile filename, (err, compiled) ->
    # use relative path if possible
    if filename.indexOf cwd == 0
      filename = (filename.replace cwd, '').replace /^\//, ''

    if err?
      log.error 'error', "failed to compile #{filename}"
      console.error if err.stderr? then err.stderr else err.stack
      return

    log.info 'compiled', filename if compiled

    cb null, compiled

# do initial compile
(require 'vigil').walk cwd, (filename) ->
  compile filename if opts.compile

# create static file server, websocket server or else noop
if opts.runServer
  app = server.createServer opts
  websocket = (require './websocket') server: app
else
  app = run: ->
  websocket = modified: ->

unless opts.forceCompile
  if opts.watch
    (require 'vigil').watch cwd, (filename, stat, isModule) ->
      unless opts.compile
        log.info 'modified', filename
        return websocket.modified filename

      compile filename, (err, compiled) ->
        unless compiled
          log.info 'modified', filename
          websocket.modified filename

  app.run()

  if opts.open
    switch os.platform()
      when 'darwin'
        exec "open http://#{opts.host}:#{opts.port}"
      when 'linux'
        exec "xdg-open http://#{opts.host}:#{opts.port}"
