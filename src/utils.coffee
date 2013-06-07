exports.logger =
  _pad: (n) ->
    n = n + ''
    if n.length >= 2 then n else new Array(2 - n.length + 1).join('0') + n

  timestamp: ->
    d     = new Date()
    year  = d.getUTCFullYear()
    month = @_pad d.getUTCMonth() + 1
    date  = @_pad d.getUTCDate()
    hour  = @_pad d.getUTCHours()
    min   = @_pad d.getUTCMinutes()
    sec   = @_pad d.getUTCSeconds()
    "#{year}-#{month}-#{date} #{hour}:#{min}:#{sec}"

  log: (level, message, metadata = '') ->
    unless level == 'error'
      return console.log "#{@timestamp()} [#{level}] #{message}", metadata

    if message instanceof Error
      [err, message] = [message, message.name]

    console.error "#{@timestamp()} [#{level}] #{message}", metadata

    if err?
      require('postmortem').prettyPrint err.stack
