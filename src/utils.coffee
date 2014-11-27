vigil = require 'vigil'

exports.log =
  info: (type, msg) ->
    console.log "  \x1B[90m#{type}\x1B[0m #{msg}"

  error: (type, msg) ->
    console.error "  \x1B[91m#{type}\x1B[0m #{msg}"


exclude = vigil.utils.excludeRe.toString()
exports.defaultExclude = new RegExp (exclude.substring 1, exclude.length-1) + '|bebop.coffee$|bebop.js$'
