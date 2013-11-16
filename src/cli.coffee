exec = require 'executive'
fs   = require 'fs'
os   = require 'os'

compilers = require './compilers'
server    = require './server'
utils     = require './utils'

error = (message) ->
  console.error message
  process.exit 1

usage = ->
  console.log """
  bebop [options]

  Options:
    --compilers, -c Specify compiler to use for a given extension
    --force-compile Compile files and exit
    --host, -h      Hostname to bind to
    --no-compile    Do not compile files automatically
    --no-watch      Do not watch files for changes
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
]

opts =
  compile:   true
  host:      'localhost'
  port:      1987
  watch:     true
  compilers: {}

# allow user to override defaults
for conf in confs
  try
    conf = require.resolve conf
  catch err
    continue

  if fs.existsSync conf
    for k,v of require conf
      opts[k] = v

args = process.argv.slice 2

while opt = args.shift()
  switch opt
    when '--help', '-v'
      usage()
    when '--open', '-o'
      opts.open = true
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
    if err?
      console.error err.toString()
      console.error err.stack
      return

    # use relative path if possible
    if filename.indexOf cwd == 0
      filename = (filename.replace cwd, '').replace /^\//, ''

    utils.log "  compiled\x1B[0m #{filename}" if compiled
    cb null, compiled

# do initial compile
(require 'vigil').walk cwd, (filename) ->
  compile filename

unless opts.forceCompile
  app = server.createServer opts

  if opts.watch
    websocket = (require './websocket') server: app

    (require 'vigil').watch cwd, (filename, stat, isModule) ->
      utils.log "  modified\x1B[0m #{filename}"

      return websocket.modified filename unless opts.compile

      compile filename, (err, compiled) ->
        websocket.modified filename unless compiled

  app.run()

  if opts.open
    switch os.platform()
      when 'darwin'
        exec "open http://#{opts.host}:#{opts.port}"
      when 'linux'
        exec "xdg-open http://#{opts.host}:#{opts.port}"
