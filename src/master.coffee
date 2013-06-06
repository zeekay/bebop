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

    if options.settings?
      @settingsModule = require.resolve path.resolve options.settings

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
      SETTINGS_MODULE:    @settingsModule ? ''

    worker.on 'message', (message) =>
      if message.type == 'uncaughtException'
        @emit 'worker:exception', worker, message

        setTimeout =>
          @fork()
        , @restartCooldown

        worker.timeout = setTimeout =>
          worker.kill()
          @emit 'worker:killed', worker
        , @forceKillTimeout

    @workers[worker.id] = worker

  # reload worker
  reload: ->
    return unless (worker = @reloading.shift())?

    worker.reloading = true

    worker.timeout = setTimeout =>
      worker.kill()
      @emit 'worker:killed', worker
    , @forceKillTimeout

    worker.send type: 'disconnect'
    @fork()

  handleExit: (worker, code, signal) ->
    delete @workers[worker.id]

    if worker.timeout?
      return clearTimeout worker.timeout

    if code != 0
      setTimeout =>
        @emit 'worker:restarting', worker
        @fork() unless @shuttingDown
      , @restartCooldown

    if @shuttingDown and Object.keys(@workers).length == 0
      process.exit 0

  handleListening: (worker, address) ->
    @emit 'worker:listening', worker, address
    @reload() if @reloading.length > 0

  handleReload: ->
    @emit 'reload'
    @reloading = (worker for id, worker of @workers when not worker.reloading)
    @reload()

  handleShutdown: ->
    return if @shuttingDown
    @shuttingDown = true

    @emit 'shutdown'

    for id, worker of @workers
      worker.send type: 'disconnect'

    setTimeout =>
      for id, worker of @workers
        worker.kill()
        @emit 'worker:killed', worker.process.pid
      process.exit 1
    , @forceKillTimeout

  run: ->
    @fork() for n in [1..@numWorkers]

    cluster.on 'exit', (worker, code, signal) =>
      @handleExit worker, code, signal
    cluster.on 'listening', (worker, address) =>
      @handleListening worker, address
    process.on 'SIGHUP', =>
      @handleReload()
    process.on 'SIGTERM', =>
      @handleShutdown()
    process.on 'SIGINT', =>
      @handleShutdown()

    # @on 'worker:exception', (worker, message) =>
    #   @logger.log 'info', 'uncaught exception', pid: worker.process.pid
    @on 'worker:listening', (worker, address) =>
      @logger.log 'info', "worker listening on #{address.address}:#{address.port}", pid: worker.process.pid
    @on 'worker:killed', (worker) =>
      @logger.log 'error', 'worker killed', pid: worker.process.pid
    @on 'worker:restarting', (worker) =>
      @logger.log 'info', 'worker restarting', pid: worker.process.pid
    @on 'shutdown', =>
      @logger.log 'info', 'shutting down'
    @on 'reload', =>
      @logger.log 'info', 'reloading'

module.exports = Master
