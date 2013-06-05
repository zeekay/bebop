cluster  = require 'cluster'
log      = require '../log'
settings = require '../settings'

PORT               = process.env.PORT or 3000
WORKERS            = process.env.WORKERS or require('os').cpus().length
RESTART_COOLDOWN   = process.env.RESTART_COOLDOWN or 2000
FORCE_KILL_TIMEOUT = process.env.FORCE_KILL_TIMOUT or 30000

shuttingDown = false
reloading    = []
workers      = {}

cluster.setupMaster
  exec : __dirname + "/worker.js"
  silent : false

# fork worker
fork = ->
  worker = cluster.fork
    PORT: PORT

  worker.on 'message', (message) ->
    if message.type == 'uncaughtException'
      log.info 'Worker died horribly', pid: worker.process.pid

      setTimeout ->
        fork()
      , RESTART_COOLDOWN

      worker.timeout = setTimeout ->
        worker.kill()
        log.error "Worker did not disconnect in time, killing it.", pid: worker.process.pid
      , FORCE_KILL_TIMEOUT

  workers[worker.id] = worker

# reload worker
reload = ->
  return unless (worker = reloading.shift())?

  worker.reloading = true

  worker.timeout = setTimeout ->
    worker.kill()
    log.error "Worker did not disconnect in time, killing it.", pid: worker.process.pid
  , FORCE_KILL_TIMEOUT

  worker.send type: 'disconnect'
  fork()

handleExit = (worker, code, signal) ->
  delete workers[worker.id]

  if worker.timeout?
    return clearTimeout worker.timeout

  if code != 0
    setTimeout ->
      log.info 'Restarting worker', pid: worker.process.pid

      fork() unless shuttingDown
    , RESTART_COOLDOWN

  if shuttingDown and Object.keys(workers).length == 0
    process.exit 0

handleListen = (worker, address) ->
  reload() if reloading.length > 0

handleReload = ->
  log.info 'Reloading openbid'
  reloading = (worker for id, worker of workers when !worker.reloading)
  reload()

handleShutdown = ->
  log.info 'Shutting down openbid'
  shuttingDown = true

  for id, worker of workers
    worker.send type: 'disconnect'

  setTimeout ->
    for id, worker of workers
      worker.kill()
      log.error "Worker did not disconnect in time, killing it.", pid: worker.process.pid
    process.exit 1
  , FORCE_KILL_TIMEOUT

module.exports =
  run: (server) ->
    log.info "Starting openbid #{settings.version}"
    fork() for n in [1..WORKERS]

    cluster.on 'exit',      handleExit
    cluster.on 'listening', handleListen
    process.on 'SIGHUP',    handleReload
    process.on 'SIGTERM',   handleShutdown
    process.on 'SIGINT',    handleShutdown
