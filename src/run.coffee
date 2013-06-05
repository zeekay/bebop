forceKillTimeout = process.env.FORCE_KILL_TIMOUT
port             = process.env.PORT
restartCooldown  = process.env.RESTART_COOLDOWN
watch            = false
workers          = process.env.WORKERS

args = process.argv.slice 2

while opt = args.shift()
  switch opt
    when '--port', '-p'
      port = parseInt args.shift(), 100
    when '--workers', '-n'
      workers = parseInt args.shift(), 10
    when '--watch', '-w'
      watch = true
    else
      if opt.charAt(0) == '-'
        throw new Error 'Unrecognized option'
      else
        server = opt

down = require './'

down.run server,
  port:    port
  workers: workers
