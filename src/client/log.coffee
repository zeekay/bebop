{root} = require './utils'

levels = [
  'debug'
  'info'
  'warn'
  'error'
]

log = ->
  return unless root.console?
  console.log.apply console, arguments

log.verbose = false

for method in levels
  do (method) ->
    log[method] = ->
      # return if (not log.verbose and method == 'debug')
      args = Array.prototype.slice.call arguments
      args.unshift 'bebop:' + method
      log.apply @, args

module.exports = log
