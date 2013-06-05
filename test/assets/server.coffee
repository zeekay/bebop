http = require 'http'

module.exports = http.createServer (req, res) ->
  res.end('hi')
