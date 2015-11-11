fs   = require 'fs'
path = require 'path'

log = require '../log'

{requireLocal} = require '../utils'


findNpm = (url) ->
  try
    path.relative process.cwd(), require.resolve url
  catch err
    path.relative process.cwd(), require.resolve url


# look for .scss|sass files inside the node_modules folder
resolveNpm = do ->
  cache = {}

  (url, file, cb) ->
    # check if the path was already found and cached
    return cb file: cache[url] if cache[url]?

    # look for modules installed through npm
    try
      newPath = findNpm url
      cache[url] = newPath # cache request
      return cb file: newPath
    catch e
      # if your module could not be found, just return the original url
      cache[url] = url
      return cb file: url
    return


module.exports = (src, dst, cb) ->
  sass = requireLocal 'node-sass'

  sass.render
    file: src
    # importer: resolveNpm
    includePaths: [path.join process.cwd(), 'node_modules' ]
    outputStyle: 'nested'
  , (err, res) ->
    throw err if err?

    fs.writeFile dst, res.css, (err) ->
      throw err if err?

      cb null, true
