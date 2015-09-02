{root} = require './utils'
Bebop  = require './bebop'

# export a few useful globals
exportGlobals: (bebop)->
  globals =
    bebop: bebop
    dir:   dir
    dump:  dump

  for key of globals
    if typeof root[key] isnt 'undefined'

      # preserve existing global
      original = root[key]
      root[key] = globals[key]
      root[key]._original = original
    else
      root[key] = globals[key]

root.Bebop = module.exports = Bebop
