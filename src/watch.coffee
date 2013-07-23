fs = require 'fs'

compilers = require './compilers'
{log}     = require './utils'

module.exports = (opts, cb) ->
  # attach websocket server
  wss = require('./websocket') opts.server

  directoryFilter = opts.directoryFilter ? ['!node_modules', '!.git']
  fileFilter = opts.fileFilter ? ['!package.json', '!.*', '!npm-debug.log', '!Cakefile', '!README.md']

  watching = {}

  walk = (dir, callback) ->
    stream = require('readdirp')
      root: dir
      directoryFilter: directoryFilter
      fileFilter: fileFilter

    stream.on 'data', (file) ->
      callback file.fullPath

  watchFile = (filename, callback) ->
    watching[filename].close() if watching[filename]

    fs.exists filename, (exists) ->
      return unless exists

      try
        watching[filename] = fs.watch filename, ->
          callback filename
          watchFile filename, callback
      catch err
        console.error err

  watch = (dir, callback) ->
    walk dir, (filename) ->
      # compile on start, if src is newer than dst
      if compilers.compile filename
        log "  compiling\x1B[0m #{'.' + filename.substr dir.length}"
        compilers.compile filename

      watchFile filename, callback

  timeout = (new Date()).getTime()

  watch opts.dir, (filename) ->
    # fs.watch fires of events too often
    now = (new Date()).getTime()
    return unless (now - timeout) > 100
    timeout = now

    log "  modified\x1B[0m #{'.' + filename.substr dir.length}"

    if compilers.compile filename
      log "  compiling\x1B[0m #{'.' + filename.substr dir.length}"
      return

    # tell browser to reload!
    wss.send
      type: 'modified'
      filename: filename

    log "  reloading"
