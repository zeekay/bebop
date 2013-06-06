cluster = require 'cluster'
events  = require 'events'
path    = require 'path'

deserialize = (exc) ->
  for frame in exc.structuredStackTrace
    {path, line, isNative, name, type, method} = frame
    do (frame, path, line, isNative, name, type, method) ->
      frame.getFileName     = -> path
      frame.getLineNumber   = -> line
      frame.isNative        = -> isNative
      frame.getFunctionName = -> name
      frame.getTypeName     = -> type
      frame.getMethodName   = -> method

  err = new Error()
  err.name                 = exc.name
  err.message              = exc.message
  err.stack                = exc.stack
  err.structuredStackTrace = exc.structuredStackTrace
  err

class Master extends events.EventEmitter
  constructor: (serverModule, options = {}) ->
    @serverModule     = require.resolve serverModule

    @forceKillTimeout = options.forceKillTimeout ? 30000
    @numWorkers       = options.workers          ? require('os').cpus().length
    @port             = options.port             ? 3000
    @restartCooldown  = options.restartCooldown  ? 2000
    @socketTimeout    = options.socketTimeout    ? 10000

    @runAs = options.runAs ?
      dropPrivileges: true
      gid: 'www-data'
      uid: 'www-data'

    @setupMaster = options.setupMaster ?
      exec : __dirname + '/worker.js'
      silent : false
    cluster.setupMaster @setupMaster

    @shuttingDown = false
    @reloading    = []
    @workers      = {}

    switch typeof options.logger
      when 'function'
        @logger = log: options.logger
      when 'object'
        @logger = options.logger
      when 'undefined'
        @logger = require 'lincoln'
      else
        @logger = false

  # fork worker
  fork: ->
    options =
      FORCE_KILL_TIMEOUT: @forceKillTimeout
      PORT:               @port
      SERVER_MODULE:      @serverModule
      SOCKET_TIMEOUT:     @socketTimeout

    if @runAs
      options.DROP_PRIVILEGES = @runAs.dropPrivileges
      options.SET_GID = @runAs.gid
      options.SET_UID = @runAs.uid

    worker = cluster.fork options

    worker.on 'message', (message) =>
      if message.type == 'uncaughtException'
        @emit 'worker:exception', worker, deserialize message.error

        setTimeout =>
          @fork()
        , @restartCooldown

        worker.timeout = setTimeout =>
          worker.kill()
          @emit 'worker:killed', worker
        , @forceKillTimeout

    @workers[worker.id] = worker

    @emit 'worker:forked', worker

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

  run: (callback) ->
    @once 'worker:listening', (worker, address) ->
      callback null

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

    if @logger
      @on 'worker:exception', (worker, err) =>
        @logger.log 'error', err, pid: worker.process.pid
      @on 'worker:listening', (worker, address) =>
        @logger.log 'info',  "worker listening on #{address.address}:#{address.port}", pid: worker.process.pid
      @on 'worker:killed', (worker) =>
        @logger.log 'error', 'worker killed', pid: worker.process.pid
      @on 'worker:restarting', (worker) =>
        @logger.log 'info',  'worker restarting', pid: worker.process.pid
      @on 'shutdown', =>
        @logger.log 'info',  'shutting down'
      @on 'reload', =>
        @logger.log 'info',  'reloading'

module.exports = Master
