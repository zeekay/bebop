import colors from 'colors/safe'

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
  std = []
  if err.stdout?
    std.push err.stdout
  if err.stderr?
    std.push err.stderr

  if std.length > 0
    std.join '\n'
  else
    msg = err.stack
    msg = msg.replace /^Error: /, ''

log = ->
  return unless root.console?
    console.log.apply console, arguments

for method, _ of theme
  do (method) ->
    prefix = colors[method] method + ' '
    log[method] = (msg, extra) ->
      err = null

      switch typeof msg
        when 'string'
          msg = msg
        when  'object'
          if msg instanceof Error
            msg = prettyError msg
          else
            msg = '\n' + prettyJSON msg

      if extra instanceof Error
        extra = prettyError extra
      else
        extra = prettyJSON extra

      if extra?
        msg = msg + '\n' + extra

      msg = prefix + msg

      if err?
        console.error msg
      else
        console.log msg

export default log
