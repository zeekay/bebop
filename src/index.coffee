Master = require './master'

wrapper =
  Master: Master
  run: (serverModule, options = {}, callback = ->) ->
    options.forceKillTimeout ?= process.env.FORCE_KILL_TIMOUT
    options.port             ?= process.env.PORT
    options.restartCooldown  ?= process.env.RESTART_COOLDOWN
    options.socketTimeout    ?= process.env.SOCKET_TIMEOUT
    options.workers          ?= process.env.WORKERS

    master = new Master serverModule, options
    master.run callback

module.exports = wrapper
