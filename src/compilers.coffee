exec = require 'executive'
fs   = require 'fs'
path = require 'path'

module.exports =
  mappings:
    coffee: 'js'
    jade: 'html'
    styl: 'css'

  compile: (filename, cb) ->
    # get extension of file modified
    ext = (path.extname filename).substr 1

    unless (compiler = @[ext])?
      return cb null, false

    src = filename
    dst = filename.replace (new RegExp ext + '$'), @mappings[ext]

    # compiler has callback, call function
    if compiler.length == 3
      return compiler src, dst, cb

    # compiler returns cmd for us to exec
    cmd = compiler src, dst

    # not a file we should compile
    unless typeof cmd is 'string'
      return cb null, false

    exec.quiet cmd, (err, stdout, stderr) ->
      return cb err if err?

      if stderr? and stderr.trim() != ''
        return cb new Error stderr

      cb null, true

  coffee: (src, dst) ->
    dst = path.dirname dst
    "coffee -bc -o #{dst} #{src}"

  jade: (src, dst) ->
    dst = path.dirname dst
    "jade --pretty #{src} --out #{dst}"

  styl: (src, dst) ->
    dst = path.dirname dst
    "stylus #{src} -o #{dst}"
