exports.logger =
  log: (level, message, metadata, callback) ->
    if typeof metadata is 'function'
      metadata()
    else
      callback()
