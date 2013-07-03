module.exports = (dir, server, opts = {}) ->
  # attach websocket server
  wss = require('./websocket') server

  directoryFilter = opts.directoryFilter ? ['!node_modules', '!.git']
  fileFilter = opts.fileFilter ? ['!package.json', '!.*', '!npm-debug.log', '!Cakefile', '!README.md']

  watching = {}

  fs = require 'fs'

  walk = (dir, callback) ->
    stream = require('readdirp')
      root: dir
      directoryFilter: directoryFilter
      fileFilter: fileFilter

    stream.on 'data', (file) ->
      callback file.fullPath

  watchFile = (filename, callback) ->
    watching[filename].close() if watching[filename]
    watching[filename] = fs.watch filename, ->
      callback filename
      watchFile filename, callback

  watch = (dir, callback) ->
    walk dir, (filename) ->
      watchFile filename, callback

  # watch files in current directory
  timeout = (new Date()).getTime()
  watch dir, (filename) ->
    now = (new Date()).getTime()

    if (now - timeout) > 100
      wss.send
        type: 'modified'
        filename: filename

    timeout = now
