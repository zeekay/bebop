{root} = require './utils'

levels = [
  'debug'
  'info'
  'warn'
  'error'
]

log = ->
  console?.log.apply console, arguments

for method in levels
  do (method) ->
    log[method] = ->
      args = Array.prototype.slice.call arguments
      args.unshift 'bebop:' + method
      log.apply @, args

module.exports = log
