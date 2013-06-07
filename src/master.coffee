cluster = require 'cluster'
events  = require 'events'
fs      = require 'fs'
path    = require 'path'

# Start up debugger
debug = ->
  for id, worker of cluster.workers
    # Only kill first worker
    pid = worker.process.pid
    require('child_process').exec "kill -s 30 #{pid}"
    return

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
    @serverModule     = require.resolve path.resolve serverModule

    @forceKillTimeout = options.forceKillTimeout ? 30000
    @numWorkers       = options.workers          ? require('os').cpus().length
    @port             = options.port             ? 3000
    @restartCooldown  = options.restartCooldown  ? 2000
    @socketTimeout    = options.socketTimeout    ? 10000
    @watchForChanges  = options.watch            ? false

    if @watchForChanges and not fs.watch
      throw new Error 'watching for changes requires fs.watch'

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
    @watched      = {}

    switch typeof options.logger
      when 'function'
        @logger = log: options.logger
      when 'object'
        @logger = options.logger
      when 'undefined'
        @logger = require('./utils').logger
      else
        @logger = false

  # fork worker
  fork: ->
    options =
      FORCE_KILL_TIMEOUT: @forceKillTimeout
      PORT:               @port
      SERVER_MODULE:      @serverModule
      SOCKET_TIMEOUT:     @socketTimeout

    if @watchForChanges
      options.WATCH_FOR_CHANGES = true

    if @runAs
      options.DROP_PRIVILEGES = @runAs.dropPrivileges
      options.SET_GID = @runAs.gid
      options.SET_UID = @runAs.uid

    worker = cluster.fork options

    worker.on 'message', (message) => @onMessage message

    @workers[worker.id] = worker

    @emit 'worker:forked', worker

  onMessage: (message) ->
    switch message.type
      when 'error'
        @emit 'worker:exception', worker, deserialize message.error

        setTimeout =>
          @fork()
        , @restartCooldown

        worker.timeout = setTimeout =>
          worker.kill()
          @emit 'worker:killed', worker
        , @forceKillTimeout

      when 'watch'
        @watch message.filename

  onExit: (worker, code, signal) ->
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

  onListening: (worker, address) ->
    @emit 'worker:listening', worker, address
    @reloadNext() if @reloading.length > 0

  # Watch files for changes
  watch: (filename) ->
    @logger.log 'debug', "watching #{filename}"

    if @watched[filename]
      @watched[filename].close()
    try
      @watched[filename] = fs.watch filename, => @reload()
    catch err
      if err.code == 'EMFILE'
        @logger.log 'Too many open files, try to increase the number of open files'
        process.exit 1
      else
        throw err

  # reload worker
  reloadNext: ->
    return unless (worker = @reloading.shift())?

    worker.reloading = true

    worker.timeout = setTimeout =>
      worker.kill()
      @emit 'worker:killed', worker
    , @forceKillTimeout

    worker.send type: 'stop'
    @fork()

  reload: ->
    return unless @running
    @emit 'reload'
    @reloading = (worker for id, worker of @workers when not worker.reloading)
    @reloadNext()

  shutdown: ->
    process.exit 1 if @shuttingDown

    @shuttingDown = true

    @emit 'shutdown'

    for id, worker of @workers
      worker.send type: 'stop'

    setTimeout =>
      for id, worker of @workers
        worker.kill()
        @emit 'worker:killed', worker
      process.exit 1
    , @forceKillTimeout

  run: (callback) ->
    @once 'worker:listening', (worker, address) =>
      @running = true
      callback null

    @fork() for n in [1..@numWorkers]

    cluster.on 'exit', (worker, code, signal) => @onExit worker, code, signal
    cluster.on 'listening', (worker, address) => @onListening worker, address

    process.on 'SIGHUP',  => @reload()
    process.on 'SIGTERM', => @shutdown()
    process.on 'SIGINT',  => @shutdown()

    if @logger
      @on 'worker:exception', (worker, err) =>
        @logger.log 'error', err, pid: worker.process.pid
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
