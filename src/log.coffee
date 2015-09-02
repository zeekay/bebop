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

      if extra?
        console.log msg, '\n' + pretty extra
      else
        console.log msg

module.exports = log
