fs   = require 'fs'
path = require 'path'
exec = require 'executive'

compilers = require './compilers'
{log}     = require './utils'

module.exports = (dir, server, opts = {}) ->
  # attach websocket server
  wss = require('./websocket') server

  directoryFilter = opts.directoryFilter ? ['!node_modules', '!.git']
  fileFilter = opts.fileFilter ? ['!package.json', '!.*', '!npm-debug.log', '!Cakefile', '!README.md']

  watching = {}

  start = timeout = (new Date()).getTime()

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

      watching[filename] = fs.watch filename, ->
        callback filename
        watchFile filename, callback

  watch = (dir, callback) ->
    walk dir, (filename) ->
      watchFile filename, callback

  watch dir, (filename) ->
    now = (new Date()).getTime()
    return unless (now - timeout) > 100

    # get extension of file modified
    ext = (path.extname filename).substr 1

    # if it's file with a known compiler, compile it, instead of reloading
    if compiler = compilers[ext]
      log "  compiling\x1B[0m #{filename}"
      return exec.quiet (compiler filename), (err, stdout, stderr) ->
        console.error stderr.trim()

    log "  modified\x1B[0m #{filename}"

    # tell browser to reload!
    wss.send
      type: 'modified'
      filename: filename

    log "  reloading"

    timeout = now
