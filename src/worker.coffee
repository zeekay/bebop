log      = require '../log'
server   = require '../server'
settings = require '../settings'

PORT               = process.env.PORT ? 3000
FORCE_KILL_TIMEOUT = process.env.FORCE_KILL_TIMOUT or 30000

shutdown = (err) ->
  try
    server.close ->
      process.exit 0 unless err?
      log.error err, pid: process.pid, -> process.exit 1
  catch _

  setTimeout (-> process.exit 1), FORCE_KILL_TIMEOUT

# log runtime errors
process.on 'uncaughtException', (err) ->
  process.send type: 'uncaughtException'
  shutdown err

# handle shutdown gracefully
process.on 'message', (message) ->
  shutdown() if message.type == 'disconnect'

server.listen PORT, ->
  log.info "Worker listening on port #{PORT}, running #{settings.version}", pid: process.pid

  # drop privileges if necessary
  if process.getgid() == 0
    process.setgid 'www-data'
    process.setuid 'www-data'

# set socket timeout
server.setTimeout 10000

process.on 'SIGTERM', -> shutdown new Error 'SIGTERM'
process.on 'SIGINT', -> shutdown new Error 'SIGINT'
