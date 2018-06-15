class Logger
  constructor: (opts = {}) ->
    @verbose opts.debug ? false

  debug: (args...) ->
    return unless @verbose()
    @log 'debug', args...

  info: (args...) ->
    return unless @verbose()
    @log 'info', args...

  warn: (args...) ->
    @log 'warn', args...

  error: (args...) ->
    @log 'error', args...

  log: (level, args...) ->
    args.unshift 'bebop:' + level
    console?.log.apply console, args

  verbose: (bool) ->
    return @_verbose unless bool?
    @_verbose = bool

export default new Logger()
