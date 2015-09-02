log = require '../log'

class EventEmitter
  constructor: (opts = {}) ->
    @debug         = opts.debug ? false
    @_listeners    = {}
    @_allListeners = []

  on: (event, callback) ->
    log.debug 'on', event, callback

    if event
      @_listeners[event] ?= []
      @_listeners[event].push callback
      # return the index of the newly added listener
      @_listeners[event].length - 1
    else
      @_allListeners.push callback
      @_allListeners.length - 1

  off: (event, index) ->
    log.debug 'off', event, index

    # remove all if no event is specified
    return @_listeners = {} unless event

    if index?
      # Remove listener at index
      @_listeners[event][index] = null
    else
      # Remove all listeners for event
      @_listeners[event] = {}
    return

  emit: (event, args...) ->
    listeners = @_listeners[event] or []
    for listener in listeners
      if listener?
        listener.apply @, args

    args.unshift event

    for listener in @_allListeners
      listener.apply @, args

    log.debug.apply log, args if @debug

module.exports = EventEmitter
