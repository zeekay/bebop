path = require 'path'
vm   = require 'vm'

module.exports = (callback) ->
  hooks = {}

  updateHooks = ->
    for ext, handler of require.extensions
      do (ext, handler) ->
        if hooks[ext] != require.extensions[ext]
          hooks[ext] = require.extensions[ext] = (module, filename) ->
            # Watch module if it hasn't been loaded before
            callback module.filename unless module.loaded

            # Invoke original handler
            handler module, filename

            # Make sure the module did not hijack the handler
            updateHooks()

  # Hook 'em.
  updateHooks()

  # Patch VM module
  methods =
    createScript:     1
    runInThisContext: 1
    runInNewContext:  2
    runInContext:     2

  for method, idx of methods
    original = vm[method]
    vm[method] = ->
      callback filename if filename = arguments[idx]
      original.apply vm, arguments
