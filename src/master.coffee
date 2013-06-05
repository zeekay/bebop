cluster = require 'cluster'
events  = require 'events'
path    = require 'path'

class Master extends events.EventEmitter
  constructor: (serverModule, options = {}) ->
    @serverModule     = require.resolve path.resolve serverModule
    @forceKillTimeout = options.forceKillTimeout ? 30000
    @numWorkers       = options.workers ? require('os').cpus().length
    @port             = options.port    ? 3000
    @restartCoolDown  = options.restartCooldown ? 2000

    # setup cluster
    @setupMaster      = options.setupMaster ?
      exec : __dirname + '/worker.js'
      silent : false
    cluster.setupMaster @setupMaster

    # setup logging
    switch typeof options.logger
      when 'undefined'
        @logger       = require 'lincoln'
        @loggerModule = require.resolve 'lincoln'
      when 'string'
        @logger       = require options.logger
        @loggerModule = require.resolve options.logger
      else
        @logger       = (require './utils').logger

    @shuttingDown = false
    @reloading    = []
    @workers      = {}

  # fork worker
  fork: ->
    worker = cluster.fork
      FORCE_KILL_TIMEOUT: @forceKillTimeout
      PORT:               @port
      LOGGER_MODULE:      @loggerModule
      SERVER_MODULE:      @serverModule

    worker.on 'message', (message) =>
      if message.type == 'uncaughtException'
        @emit 'worker:exception'
        @logger.log 'info', 'uncaught exception', pid: worker.process.pid

        setTimeout =>
          @fork()
        , @restartCooldown

        worker.timeout = setTimeout =>
          worker.kill()
          @emit 'worker:killed'
          @logger.log 'error', 'worker killed', pid: worker.process.pid
        , @forceKillTimeout

    @workers[worker.id] = worker

  # reload worker
  reload: ->
    return unless (worker = @reloading.shift())?

    worker.reloading = true

    worker.timeout = setTimeout =>
      worker.kill()
      logger.error "Worker did not disconnect in time, killing it.", pid: worker.process.pid
    , FORCE_KILL_TIMEOUT

    worker.send type: 'disconnect'
    @fork()

  handleExit: (worker, code, signal) ->
    delete @workers[worker.id]

    if worker.timeout?
      return clearTimeout worker.timeout

    if code != 0
      setTimeout =>
        @logger.log 'info', 'Restarting worker', pid: worker.process.pid
        @fork() unless @shuttingDown
      , @restartCooldown

    if @shuttingDown and Object.keys(@workers).length == 0
      process.exit 0

  handleListen: (worker, address) ->
    @emit 'listening', worker: worker, address: address
    @reload() if @reloading.length > 0

  handleReload: ->
    @emit 'reload'
    @logger.log 'info', 'reloading'

    @reloading = (worker for id, worker of @workers when not worker.reloading)
    @reload()

  handleShutdown: ->
    @emit 'shutdown'
    @logger.log 'info', 'shutting down'

    shuttingDown = true

    for id, worker of @workers
      worker.send type: 'disconnect'

    setTimeout =>
      for id, worker of @workers
        worker.kill()

        @emit 'worker:killed', pid: worker.process.pid
        @logger.log 'error', 'worker killed', pid: worker.process.pid

      process.exit 1
    , @forceKillTimeout

  run: ->
    @fork() for n in [1..@numWorkers]

    cluster.on 'exit',      => @handleExit()
    cluster.on 'listening', => @handleListen()
    process.on 'SIGHUP',    => @handleReload()
    process.on 'SIGTERM',   => @handleShutdown()
    process.on 'SIGINT',    => @handleShutdown()

module.exports = Master
