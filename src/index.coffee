Master = require './master'

wrapper = (serverModule, options) ->
  new Master serverModule, options

wrapper.Master = Master

module.exports = wrapper
