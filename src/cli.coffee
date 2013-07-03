bebop = require './'
xian = require 'xian'

error = (message) ->
  console.error message
  process.exit 1

usage = ->
  console.log """
  bebop [options]

  Options:
    --port, -p    Specify port to listen on
    --secure, -s  Require authentication
  """
  process.exit 0

args = process.argv.slice 2
opts =
  watch: true

while opt = args.shift()
  switch opt
    when '--help', '-v'
      usage()
    when '--no-watch'
      opts.watch = false
    when '--port', '-p'
      opts.port = parseInt args.shift(), 10
    when '--secure', '-s'
      [opts.user, opts.pass] = args.shift.split(':')
    else
      error 'Unrecognized option' if opt.charAt(0) is '-'

server = bebop.server.createServer opts
bebop.watch process.cwd(), server
server.run()
