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
  compilers:
    coffee: (src, dst) ->
      dst = path.dirname dst
      "coffee -bc -o #{dst} #{src}"

    jade: (src, dst) ->
      dst = path.dirname dst
      "jade #{src} --out #{dst}"

    styl: (src, dst) ->
      dst = path.dirname dst
      "stylus #{src} -o #{dst}"

  mappings:
    coffee: 'js'
    jade: 'html'
    styl: 'css'

  compile: (opts) ->
    [src, dst] = opts
    compilers = {}
    mappings  = {}

    for k,v of @mappings
      mappings[k] = v

    for k,v of @compilers
      compilers[k] = v

    for k,v of opts.mappings
      mappings[k] = v

    for k,v of opts.compilers
      compilers[k] = v

    # get extension of file modified
    ext = (path.extname src).substr 1

    unless (compiler = @[ext])?
      return false

    dst ?= src.replace (new RegExp ext + '$'), @mappings[ext]

    # only compile if src file has been modified since last compilation
    checkModified src, dst, (newer) ->
      return unless newer

      # if we're passed a string, exec command
      if typeof (cmd = compiler src, dst) is 'string'
        exec.quiet cmd, (err, stdout, stderr) ->
          if (stderr = stderr.trim()) != ''
            console.error stderr
    true
