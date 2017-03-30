import dir from './dir'

# inspired by https://github.com/douglascrockford/JSON-js/blob/master/cycle.js
export default (object, cb) ->
  objects = []
  paths = []

  derez = (value, path) =>
    switch typeof value
      when 'object'
        return null  unless value
        i = 0
        while i < objects.length
          return $ref: paths[i]  if objects[i] is value
          i += 1
        objects.push value
        paths.push path
        if Object::toString.apply(value) is '[object Array]'
          nu = []
          i = 0
          while i < value.length
            nu[i] = derez(value[i], path + '[' + i + ']')
            i += 1
        else
          nu = {}
          properties = dir(value)
          for i of properties
            name = properties[i]
            if typeof value[name] is 'function'

              # Crop source
              funcname = (value[name].toString().split(')')[0] + ')').replace(' ' + name, '')

              # Don't recurse farther if function doesn't have valid properties
              if dir(value[name]).length < 1
                nu[name] = funcname
              else
                try
                  nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
            else
              try
                nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
        nu

      when 'number', 'string', 'boolean'
        value

      when 'function'
        try
          properties = dir(value)
          objects.push value
          paths.push path
          nu = {}
          for i of properties
            name = properties[i]
            if typeof value[name] is 'function'

              # Prettify name for JSON
              funcname = (value[name].toString().split(')')[0] + ')').replace(' ' + name, '')

              # Don't recurse farther if function doesn't have valid properties
              if dir(value[name]).length < 1
                nu[name] = funcname
              else
                nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
            else
              nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
          return nu
        catch e
          return nu

  derez object, '$'
