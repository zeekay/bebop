exec = require 'executive'
fs   = require 'fs'
os   = require 'os'

error = (message) ->
  console.error message
  process.exit 1

usage = ->
  console.log """
  bebop [options]

  Options:
    --host, -h      Hostname to bind to
    --port, -p      Port to listen on
    --secure, -s    Require authentication
    --open, -o      Open browser automatically
    --no-watch      Do not watch files for changes
    --no-compile    Do not compile files automatically
    --force-compile Compile files and exit
  """
  process.exit 0

opts =
  compile: true
  host: '0.0.0.0'
  port: 3000
  watch:   true

confs = [
  process.env.HOME + '/.bebop'
  process.cwd() + '/.bebop'
]

require.extensions['.coffee'] = ->
  require 'coffee-script'
  require.extensions['.coffee'].apply require.extensions, arguments

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
      opts.openBrowser = true
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
    else
      error 'Unrecognized option' if opt.charAt(0) is '-'

compilers = require './compilers'
server    = require './server'
utils     = require './utils'

compile = (filename, cb = ->) ->
  compilers.compile filename, (err, compiled) ->
    if err?
      console.error err.toString()
      console.error err.stack
      return

    if compiled
      utils.log "  compiled\x1B[0m #{filename}"
      cb null

(require 'vigil').walk process.cwd(), (filename) ->
  compile filename

unless opts.forceCompile
  app = server.createServer opts

  if opts.watch
    websocket = (require './websocket') server: app

    (require 'vigil').watch process.cwd(), (filename, stat, isModule) ->
      utils.log "  modified\x1B[0m #{filename}"

      unless opts.compile
        return websocket.modified filename

      compile filename, (err, compiled) ->
        websocket.modified filename unless compiled

  app.run()

  if opts.openBrowser
    switch os.platform()
      when 'darwin'
        exec "open http://#{opts.host}:#{opts.port}"
      when 'linux'
        exec "xdg-open http://#{opts.host}:#{opts.port}"
