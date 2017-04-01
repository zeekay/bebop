import {root} from './utils'

levels = [
  'debug'
  'info'
  'warn'
  'error'
]

class Logger
  constructor: (options) ->
    for level in levels
      do (level) =>
        @[level] = =>
          args = Array.prototype.slice.call arguments
          args.unshift 'bebop:' + level
          @log.apply @, args

  log: ->
    console?.log.apply console, arguments

  setLevels: (levels) ->
    @levels = levels

  debug: (enable) ->
    if enable
      @setLevels levels
    else
      @setLevels ['info', 'warning', 'error']

export default new Logger()
