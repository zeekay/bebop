Bebop = require './bebop'
dir   = require './dir'
dump  = require './dump'

{root} = require './utils'

exportGlobals = (bebop)->
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

Bebop.start = (opts = {}) ->
  # Create new Bebop Instance
  root.bebop = bebop = new Bebop opts

  # Setup repl for Node clients
  if opts.useRepl
    repl = require 'repl'
    util = require 'util'

    # colorful output
    repl.writer = (obj, showHidden, depth) ->
      util.inspect obj, showHidden, depth, true

    bebop.onopen = ->
      repl.start 'bebop> ', null, null, true

  # Export a few useful globals
  exportGlobals bebop

  # Autoconnect
  bebop.connect()

root.Bebop = module.exports = Bebop
