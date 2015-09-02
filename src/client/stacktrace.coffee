stringifyArguments = (args) ->
  result = []
  slice = Array::slice
  i = 0

  while i < args.length
    arg = args[i]
    if arg is undefined
      result[i] = 'undefined'
    else if arg is null
      result[i] = 'null'
    else if arg.constructor
      if arg.constructor is Array
        if arg.length < 3
          result[i] = '[' + stringifyArguments(arg) + ']'
        else
          result[i] = '[' + stringifyArguments(slice.call(arg, 0, 1)) + '...' + stringifyArguments(slice.call(arg, -1)) + ']'
      else if arg.constructor is Object
        result[i] = '#object'
      else if arg.constructor is Function
        result[i] = '#function'
      else if arg.constructor is String
        result[i] = '"' + arg + '"'
      else result[i] = arg  if arg.constructor is Number
    ++i
  result.join ','

chrome = (e) ->
  stack = (e.stack + '\n').replace(/^\S[^\(]+?[\n$]/g, '').replace(/^\s+(at eval )?at\s+/g, '').replace(/^([^\(]+?)([\n$])/g, '{anonymous}()@$1$2').replace(/^Object.<anonymous>\s*\(([^\)]+)\)/g, '{anonymous}()@$1').split('\n')
  stack.pop()
  stack

firefox = (e) ->
  e.stack.replace(/(?:\n@:0)?\s+$/m, '').replace(/^\(/g, '{anonymous}(').split '\n'

other = (curr) ->
  ANON = '{anonymous}'
  fnRE = /function\s*([\w\-$]+)?\s*\(/i
  stack = []
  fn = undefined
  args = undefined
  maxStackSize = 10
  while curr and curr['arguments'] and stack.length < maxStackSize
    fn = (if fnRE.test(curr.toString()) then RegExp.$1 or ANON else ANON)
    args = Array::slice.call(curr['arguments'] or [])
    stack[stack.length] = fn + '(' + stringifyArguments(args) + ')'
    curr = curr.caller
  stack

# Stacktrace, borrowed from https://github.com/eriwen/javascript-stacktrace
module.exports = (e) ->
  if e['arguments'] and e.stack
    return method.chrome(e)

  if e.stack
    return method.firefox(e)

  method.other e
