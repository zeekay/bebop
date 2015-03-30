exec = require 'executive'
fs   = require 'fs'
os   = require 'os'

vigil = require 'vigil'

compilers             = require './compilers'
server                = require './server'
{defaultExclude, log} = require './utils'

error = (message) ->
  console.error message
  process.exit 1

usage = ->
  console.log """
  bebop [options] [file]

  Options:
    --compile-only  Compile files and exit
    --compilers,    Specify compiler to use for a given extension
    --config, -c    Specify bebop.coffee to use
    --exclude, -x   Exclude files for watching, compiling
    --force-reload  Force reload when file is compiled
    --host, -h      Hostname to bind to
    --include, -i   Include files for watching, compiling
    --no-compile    Do not compile files automatically
    --no-server     Do not run static file server
    --no-watch      Do not watch files for changes
    --open, -o      Open browser automatically
    --port, -p      Port to listen on
    --pre           Command to execute first
    --secure, -s    Require authentication
    --static-dir    Directory used as root for static file server
    --work-dir      Directory used as root for compiling, watching
  """
  process.exit 0

require.extensions['.coffee'] = ->
  require 'coffee-script/register'
  require.extensions['.coffee'].apply require.extensions, arguments

cwd = process.cwd()

confs = [
  process.env.HOME + '/.bebop'
  cwd + '/.bebop'
  cwd + '/bebop'
]

opts =
  compile:        true
  compileOnly:    false
  compilers:      {}
  defaultExclude: true
  exclude:        []
  forceReload:    false
  host:           'localhost'
  include:        []
  index:          ''
  port:           1987
  pre:            (done) -> done()
  runServer:      true
  staticDir:      cwd
  workDir:        cwd
  watch:          true

# require config file and override opts
requireConfig = (path) ->
  try
    conf = require.resolve path
  catch err
    return

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
    when '--compile-only'
      opts.compileOnly = true
    when '--include', '-i'
      opts.include.push new RegExp args.shift()
    when '--exclude', '-x'
      opts.exclude.push new RegExp args.shift()
    when '--no-default-exclude'
      opts.defaultExclude = false
    when '--force-reload'
      opts.forceReload = true
    when '--host', '-h'
      opts.host = args.shift()
    when '--pre'
      cmd = args.shift()
      opts.pre = (done) -> exec cmd, done
    when '--port', '-p'
      opts.port = parseInt args.shift(), 10
    when '--secure', '-s'
      credentials = args.shift()
      if credentials
        [opts.user, opts.pass] = credentials.split(':')
      else
        opts.user = 'bebop'
        opts.pass = 'beepboop'
    when '--static-dir'
      opts.staticDir = args.shift()
    when '--work-dir'
      opts.workDir = args.shift()
    when '--compilers', '-c'
      for compiler in args.shift().split ','
        [ext, mod] = compiler.split ':'
        opts.compilers[ext] = mod
    else
      if opt.charAt(0) is '-'
        error 'Unrecognized option'
      else
        opts.index = opt

# Setup include/expludes
if opts.defaultExclude
  opts.exclude = [vigil.utils.excludeRe, defaultExclude].concat opts.exclude

if opts.include.length == 0
  opts.include = null

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

# compile helper
compile = (filename, cb = ->) ->
  compilers.compile filename, (err, compiled) ->
    # use relative path if possible
    if filename.indexOf opts.workDir == 0
      filename = (filename.replace opts.workDir, '').replace /^\//, ''

    if err?
      log.error 'error', "failed to compile #{filename}"
      console.error if err.stderr? then err.stderr else err.stack
      return

    log.info 'compiled', filename if compiled

    cb null, compiled

# Let's bop!
opts.pre (err) ->
  return if err?

  # Do initial compile
  if opts.compile
    vigil.walk opts.workDir, vigilOpts, (filename) ->
      compile filename if opts.compile

  return if opts.compileOnly
    return

  if opts.runServer
    app = server.createServer opts
    websocket = (require './websocket') server: app
  else
    app = run: ->
    websocket = modified: ->

  if opts.watch
    # Start watch cycle
    vigil.watch opts.workDir, vigilOpts, (filename, stat, isModule) ->
      unless opts.compile
        log.info 'modified', filename
        return websocket.modified filename
      compile filename, (err, compiled) ->
        unless compiled
          log.info 'modified', filename
          websocket.modified filename
        else
          if opts.forceReload
            websocket.modified filename

  # Start server
  app.run()

  # Open browser window
  if opts.open or opts.index != ''
    switch os.platform()
      when 'darwin'
        exec "open http://#{opts.host}:#{opts.port}/#{opts.index}"
      when 'linux'
        exec "xdg-open http://#{opts.host}:#{opts.port}/#{opts.index}"
