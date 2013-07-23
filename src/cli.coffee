exec = require 'executive'
fs   = require 'fs'
os   = require 'os'
# xian = require 'xian'

bebop = require './'

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
    --no-browser    Do not open browser automatically
    --no-watch      Do not watch files for changes
    --no-compile    Do not compile files automatically
    --force-compile Compile files and exit
  """
  process.exit 0

opts =
  browser: true
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
    when '--no-browser'
      opts.browser = false
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

server = bebop.server.createServer opts

if opts.watch
  bebop.watch
    dir: process.cwd(),
    server: server
    compile: opts.compile
  , -> process.exit 0 if opts.forceCompile

server.run()

if opts.browser
  switch os.platform()
    when 'darwin'
      exec "open http://#{opts.host}:#{opts.port}"
    when 'linux'
      exec "xdg-open http://#{opts.host}:#{opts.port}"
