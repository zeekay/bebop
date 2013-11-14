exec = require 'executive'
fs   = require 'fs'
path = require 'path'

checkModified = (src, dst, cb) ->
  fs.stat src, (err, stat) ->
    return cb err if err

    mtime = stat.mtime
    fs.stat dst, (err, stat) ->
      return cb err if err

      cb mtime > stat.mtime

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
    unless typeof (cmd = compiler src, dst) is 'string'
      return cb null, false

    # only compile if src file has been modified since last compilation
    checkModified src, dst, (newer) ->
      return unless newer

        exec.quiet cmd, (err, stdout, stderr) ->
          if stderr? and stderr.trim() != ''
            cb new Error stderr
          else
            cb null, true

  coffee: (src, dst) ->
    dst = path.dirname dst
    "coffee -bc -o #{dst} #{src}"

  jade: (src, dst) ->
    dst = path.dirname dst
    "jade #{src} --out #{dst}"

  styl: (src, dst) ->
    dst = path.dirname dst
    "stylus #{src} -o #{dst}"
