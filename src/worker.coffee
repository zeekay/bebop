server = require process.env.SERVER_MODULE
utils  = require './utils'

FORCE_KILL_TIMEOUT = process.env.FORCE_KILL_TIMOUT or 30000
PORT               = process.env.PORT ? 3000
LOGGER_MODULE      = process.env.LOGGER_MODULE
SERVER_MODULE      = process.env.SERVER_MODULE
SETTINGS_MODULE    = process.env.SETTINGS_MODULE

server = require SERVER_MODULE

if LOGGER_MODULE?
  logger = require LOGGER_MODULE
else
  logger = (require './utils').logger

log = (level, message, meta, callback) ->
  logger.log level, message, meta, callback

if SETTINGS_MODULE?
  settings = require SETTINGS_MODULE
else
  settings =
    version: ''

shuttingDown = false

shutdown = (err) ->
  return if shuttingDown
  shuttingDown = true

  try
    server.close -> process.exit 0
  catch _

  setTimeout (-> process.exit 1), FORCE_KILL_TIMEOUT

# log runtime errors
process.on 'uncaughtException', (err) ->
  log 'error', err, pid: process.pid, ->
    process.send type: 'uncaughtException'
    shutdown err

# handle shutdown gracefully
process.on 'message', (message) ->
  shutdown() if message.type == 'disconnect'

listening = ->
  log 'info', "Worker listening on port #{PORT}, running #{settings.version}", pid: process.pid

  # drop privileges if necessary
  if process.getgid() == 0
    process.setgid 'www-data'
    process.setuid 'www-data'

server.listen PORT, listening

# set socket timeout
server.setTimeout 10000

process.on 'SIGTERM', -> shutdown()
process.on 'SIGINT', -> shutdown()
