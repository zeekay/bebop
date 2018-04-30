import fs   from 'fs'
import path from 'path'


defaultPaths = (opts) ->
  exts      = ['.html', '.htm', '.txt', '.md']
  basePaths = [opts.assetDir, opts.buildDir, opts.workDir]
  pathSet   = {}

  for p in basePaths
    for ext in exts
      pathSet[path.join p, '404' + ext] = true

  # Return just unique paths
  Object.keys pathSet


export default render404 = (opts = {}) ->
  page404 = opts.page404 ? ''

  unless page404 != ''
    for p in defaultPaths opts
      do (p) ->
        fs.access p, (err) ->
          unless err?
            page404 = p
            console.log 'detected 404 page:', page404

  (req, res, next) ->
    return next() unless page404

    now = new Date().toUTCString()
    res.setHeader 'Content-Type',  'text/html; charset=UTF-8'
    res.setHeader 'Cache-Control', 'public, max-age=' + 0
    res.setHeader 'Date',          now unless res.getHeader 'Date'
    res.setHeader 'Last-Modified', now unless res.getHeader 'Last-Modified'

    if req.method == 'HEAD'
      res.writeHead 200
      return res.end()

    if req.method != 'GET'
      return next()

    fs.readFile page404, 'utf-8', (err, data) ->
      throw err if err?

      res.writeHead 404
      res.end data
