master = require './master'

module.exports =
  run: (server, options = {}) ->
    master require.resolve server, options
