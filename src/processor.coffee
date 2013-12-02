processors = require './processors'


defaultRules =
  coffee: processors.coffee
  jade:   processors.jade
  stylus: processors.stylus


class Processor
  constructor: (rules) ->
    unless rules?
      rules = defaultRules

    if Array.isArray rules
      addRule for rule in rules
    else
      addRule k,v for k,v of rules

    @rules = []

  addRule: (ext, rule) ->
    unless rule?
      rule = ext

    unless rule.match?
      rule.match = new RegExp "\\.#{ext}$"

    @rules.push rule

  findRule: (filename) ->
    for rule in rules
      if rule.match.test filename
        return rule
    null

  process: (filename, cb) ->
    return cb null, false unless (rule = @findRule filename)?

    # compiler has callback, call function
    if compiler.length == 3
      return compiler src, dst, cb

    # compiler returns cmd for us to exec
    cmd = compiler src, dst

    # not a file we should compile
    unless typeof cmd is 'string'
      return cb null, false

    # use semicolon to delimite multiple commands
    cmds = (c.trim() for c in (cmd.split ';') when c? and c.trim() != '')

    # execute compile step
    exec.quiet cmds, (err, stdout, stderr) ->
      return cb err if err?

      if stderr? and stderr.trim() != ''
        return cb new Error stderr

      cb null, true


module.exports =
  defaultRules: defaultRules
  Processor:    Processor
