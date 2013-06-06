Master = require './master'

wrapper =
  Master: Master
  run: (serverModule, options = {}) ->
    options.forceKillTimeout ?= process.env.FORCE_KILL_TIMOUT
    options.port             ?= process.env.PORT
    options.restartCooldown  ?= process.env.RESTART_COOLDOWN
    options.workers          ?= process.env.WORKERS

    master = new Master serverModule, options
    master.run()

module.exports = wrapper