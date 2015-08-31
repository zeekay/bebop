exports.log =
  info: (type, msg) ->
    console.log "  \x1B[90m#{type}\x1B[0m #{msg}"

  error: (type, msg) ->
    console.error "  \x1B[91m#{type}\x1B[0m #{msg}"

exports.defaultExclude = /bebop.coffee$|bebop.js$|^_/
