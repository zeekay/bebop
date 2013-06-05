server = require process.env.SERVER_MODULE
utils  = require './utils'

FORCE_KILL_TIMEOUT = process.env.FORCE_KILL_TIMOUT or 30000
PORT               = process.env.PORT ? 3000
LOGGER_MODULE      = process.env.LOGGER_MODULE
SERVER_MODULE      = process.env.SERVER_MODULE

console.log SERVER_MODULE
console.log LOGGER_MODULE

server = require SERVER_MODULE

if LOGGER_MODULE?
  logger = require LOGGER_MODULE
else
  logger = (require './utils').logger

shutdown = (err) ->
  try
    server.close ->
      process.exit 0 unless err?
      logger.log 'error', err, pid: process.pid, -> process.exit 1
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
  # drop privileges if necessary
  if process.getgid() == 0
    process.setgid 'www-data'
    process.setuid 'www-data'

# set socket timeout
server.setTimeout 10000

process.on 'SIGTERM', -> shutdown new Error 'SIGTERM'
process.on 'SIGINT', -> shutdown new Error 'SIGINT'
