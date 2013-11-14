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

  compile: (filename) ->
    # get extension of file modified
    ext = (path.extname filename).substr 1

    unless (compiler = @[ext])?
      return false

    src = filename
    dst = filename.replace (new RegExp ext + '$'), @mappings[ext]

    # only compile if src file has been modified since last compilation
    checkModified src, dst, (newer) ->
      return unless newer

      # if we're passed a string, exec command
      if typeof (cmd = compiler src, dst) is 'string'
        exec.quiet cmd, (err, stdout, stderr) ->
          if stderr? and stderr.trim() != ''
            console.error stderr
    true

  coffee: (src, dst) ->
    dst = path.dirname dst
    "coffee -bc -o #{dst} #{src}"

  jade: (src, dst) ->
    dst = path.dirname dst
    "jade #{src} --out #{dst}"

  styl: (src, dst) ->
    dst = path.dirname dst
    "stylus #{src} -o #{dst}"
