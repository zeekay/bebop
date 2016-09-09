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

prettyJSON = (obj) ->
  JSON.stringify obj, null, 2

prettyError = (err) ->
  msg = err.toString()
  if err.stdout?
    msg += err.stdout
  if err.stderr?
    msg += err.stderr
  msg += '\n' + err.stack
  msg

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
        msg = prettyError msg

      if extra instanceof Error
        extra = prettyError extra
      else
        extra = prettyJSON extra

      if extra?
        msg = msg + '\n' + extra

      if err?
        console.error msg
      else
        console.log msg

module.exports = log
