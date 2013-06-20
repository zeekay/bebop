try
  require 'coffee-script'
catch err

require('postmortem').install()

{ FORCE_KILL_TIMEOUT
  PORT
  SERVER_MODULE
  SOCKET_TIMEOUT
  DROP_PRIVILEGES
  SET_GID
  SET_UID } = process.env

shuttingDown = false

serialize = (err) ->
  message:              err.message
  name:                 err.name
  stack:                err.stack
  structuredStackTrace: err.structuredStackTrace

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
  process.send type: 'error', error: serialize err
  shutdown()

# handle shutdown gracefully
process.on 'message', (message) ->
  return if shuttingDown or not message?.type

  switch message.type
    when 'stop'
      shutdown()

server = require SERVER_MODULE

server.listen PORT, ->
  if DROP_PRIVILEGES and process.getgid() == 0
    process.setgid SET_GID
    process.setuid SET_UID

# set socket timeout
server.setTimeout SOCKET_TIMEOUT

process.on 'SIGTERM', -> shutdown()
process.on 'SIGINT', -> shutdown()
