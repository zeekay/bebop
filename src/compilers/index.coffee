exec       = require 'executive'
fs         = require 'fs'
isFunction = require 'is-function'
isPromise  = require 'is-promise'
isString   = require 'is-string'
path       = require 'path'

sass = require './sass'

{requireLocal} = require '../utils'

module.exports =
  mappings:
    coffee: 'js'
    hbs:    'html'
    jade:   'html'
    sass:   'css'
    scss:   'css'
    styl:   'css'

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

    if isFunction cmd
      console.log 'isFunction'
      return cmd cb
    if isPromise cmd
      console.log 'isPromise'
      return cmd
    unless isString cmd
      console.log '!isString'
      return cb null, cmd ? false

    console.log 'isString'

    # use semicolon to delimite multiple commands
    cmds = (c.trim() for c in (cmd.split ';') when c? and c.trim() != '')

    # execute compile step
    exec.quiet cmds, (err, stdout, stderr) ->
      return cb err if err?

      if stderr? and stderr.trim() != ''
        return cb new Error stderr

      cb null, true

  coffee: (src, dst) ->
    dst = path.dirname dst
    "coffee -bmc -o #{dst} #{src}"

  jade: (src, dst) ->
    dst = path.dirname dst
    "jade --pretty #{src} --out #{dst}"

  hbs: (src, dst) ->
    handlebars = requireLocal 'handlebars'
    template = handlebars.compile fs.readFileSync src, 'utf8'
    fs.writeFileSync dst, (template {}), 'utf8'

  styl: (src, dst) ->
    dst = path.dirname dst
    "stylus #{src} -o #{dst}"

  sass: sass
  scss: sass
