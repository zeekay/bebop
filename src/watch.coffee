fs   = require 'fs'
path = require 'path'
vm   = require 'vm'

patcher = (obj) ->
  patched = []
  patcher =
    patch: (name, func) ->
      original = obj[name]
      if typeof original is 'function'
        wrapper = ->
          original.apply obj, arguments
        replacement = func wrapper
      else
        replacement = func original
      obj[name] = replacement
      patched.push [name, original]
      return

    unpatch: ->
      while patched.length
        [name, original] = patched.pop()
        if original
          obj[name] = original
        else
          delete obj[name]
      return

hooks = {}

updateHooks = ->
  for ext, handler of require.extensions
    do (ext, handler) ->
      if hooks[ext] != require.extensions[ext]
        hooks[ext] = require.extensions[ext] = (module, filename) ->
          # Watch module if it hasn't been loaded before
          process.send
            type: 'watch'
            filename: module.filename unless module.loaded

          # Invoke original handler
          handler module, filename

          # Make sure the module did not hijack the handler
          updateHooks()

# Hook 'em.
updateHooks()

# Patch VM module.
{patch} = patcher vm
methods =
  createScript: 1
  runInThisContext: 1
  runInNewContext: 2
  runInContext: 2

for method, idx of methods
  patch method, (original) ->
    ->
      fs.watch(file) if file = arguments[idx]
      original arguments
