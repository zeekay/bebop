class EventEmitter
  constructor: (opts = {}) ->
    @debug         = opts.debug ? false
    @_listeners    = {}
    @_allListeners = []

  on: (event, callback) ->
    if event
      @_listeners[event] ?= []
      @_listeners[event].push callback
      # return the index of the newly added listener
      @_listeners[event].length - 1
    else
      @_allListeners.push callback
      @_allListeners.length - 1

  off: (event, index) ->
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

    if @debug
      console.log.apply console, args

module.exports = EventEmitter
