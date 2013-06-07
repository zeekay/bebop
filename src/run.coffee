args = process.argv.slice 2

error = (message) ->
  console.error message
  process.exit 1

usage = ->
  console.log '''
  xian server.js [options]

  Options:
    --port       Specify port to listen on.
    --workers    Number of workers to start.
    --watch      Reload on changes
  '''
  process.exit 0

serverModule = args.shift()

while opt = args.shift()
  switch opt
    when '--port', '-p'
      port = parseInt args.shift(), 10
    when '--workers', '-n'
      workers = parseInt args.shift(), 10
    when '--watch', '-w'
      watch = true
    when '--force-kill'
      forceKillTimeout = parseInt args.shift(), 10
    when '--restart-cooldown'
      restartCooldown = parseInt args.shift(), 10
    when '--help', '-h'
      usage()
    else
      if opt.charAt(0) == '-'
        error 'Unrecognized option'

unless serverModule?
  usage()

require('./').run serverModule,
  forceKillTimeout: forceKillTimeout
  port:             port
  restartCooldown:  restartCooldown
  workers:          workers
  watch:            watch
