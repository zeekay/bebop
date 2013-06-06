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

if SETTINGS_MODULE?
  settings = require SETTINGS_MODULE
else
  settings =
    version: ''

shuttingDown = false

shutdown = ->
  return if shuttingDown
  shuttingDown = true

  try
    server.close -> process.exit 0
  catch _

  setTimeout (-> process.exit 0), FORCE_KILL_TIMEOUT

# log runtime errors
process.on 'uncaughtException', (err) ->
  logger.log 'error', err, pid: process.pid, ->
    process.send type: 'uncaughtException'
    shutdown()

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

process.on 'SIGTERM', -> shutdown()
process.on 'SIGINT', -> shutdown()
