path = require 'path'
vm   = require 'vm'

hooks = {}

updateHooks = ->
  for ext, handler of require.extensions
    do (ext, handler) ->
      if hooks[ext] != require.extensions[ext]
        hooks[ext] = require.extensions[ext] = (module, filename) ->
          unless module.loaded
            # Watch module if it hasn't been loaded before
            process.send
              type: 'watch'
              filename: module.filename

            # Invoke original handler
            handler module, filename

            # Make sure the module did not hijack the handler
            updateHooks()

# Hook 'em.
updateHooks()

# Patch VM module.
methods =
  createScript: 1
  runInThisContext: 1
  runInNewContext: 2
  runInContext: 2

for method, idx of methods
  do (method, idx) ->
    original = vm[method]
    vm[method] = ->
      if filename = arguments[idx]
        process.send
          type: 'watch'
          filename: filename
      original.apply vm, arguments
