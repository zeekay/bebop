colors = require 'colors/safe'

colors.setTheme
  silly:   'rainbow'
  input:   'grey'
  verbose: 'cyan'
  prompt:  'grey'
  info:    'green'
  data:    'grey'
  help:    'cyan'
  warn:    'yellow'
  debug:   'blue'
  error:   'red'

pretty = (obj) ->
  JSON.stringify obj, null, 2

log = ->
  console.log.apply console, arguments

for method in ['debug', 'info', 'warn', 'error']
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
