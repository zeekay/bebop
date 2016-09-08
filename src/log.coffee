colors = require 'colors/safe'

theme =
  debug:    'blue'
  info:     'white'
  warn:     'yellow'
  error:    'red'

  bebop:    'black'
  modified: 'cyan'
  compiled: 'blue'

colors.setTheme theme

pretty = (obj) ->
  JSON.stringify obj, null, 2

log = ->
  return unless root.console?
    console.log.apply console, arguments

for method, _ of theme
  do (method) ->
    prefix = colors[method] method + ' '
    log[method] = (msg, extra) ->
      if typeof msg == 'string'
        msg = prefix + msg
      else
        msg = prefix + '\n' + pretty msg

      err = null

      # detect errors
      if msg instanceof Error
        err = msg
        msg = err.toString()

        unless extra?
          extra = err.stack

      if extra instanceof Error
        err = extra
        extra = err.toString()
        extra = '\n' + err.stack

      if extra?
        msg = msg + '\n' + pretty extra

      if err?
        console.error msg
      else
        console.log msg

module.exports = log
