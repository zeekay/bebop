lincoln = require 'lincoln'
lincoln.stacktrace.install()

FORCE_KILL_TIMEOUT = process.env.FORCE_KILL_TIMOUT or 30000
PORT               = process.env.PORT ? 3000
SERVER_MODULE      = process.env.SERVER_MODULE

shuttingDown = false

shutdown = ->
  return if shuttingDown
  shuttingDown = true

  try
    server.close -> process.exit 0
  catch _

  setTimeout ->
    process.exit 0
  , FORCE_KILL_TIMEOUT

# marshal runtime errors back to master process
process.on 'uncaughtException', (err) ->
  message              = err.message
  name                 = err.toString()
  stack                = err.stack
  structuredStackTrace = err.structuredStackTrace

  process.send type: 'uncaughtException', error:
    message:              message
    name:                 name
    stack:                stack
    structuredStackTrace: structuredStackTrace

  shutdown()

# handle shutdown gracefully
process.on 'message', (message) ->
  shutdown() if message.type == 'disconnect'

server = require SERVER_MODULE
server.listen PORT, ->
  # drop privileges if necessary
  if process.getgid() == 0
    process.setgid 'www-data'
    process.setuid 'www-data'

# set socket timeout
server.setTimeout 10000

process.on 'SIGTERM', -> shutdown()
process.on 'SIGINT', -> shutdown()
