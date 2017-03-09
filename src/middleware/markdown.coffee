import fs     from 'fs'
import marked from 'marked'
import url    from 'url'

import css    from '../assets/github-markdown.css'

class Markdown
  constructor: (opts = {}) ->
/   maxAge = opts.maxAge or 0

    marked.setOptions
      renderer: new marked.Renderer()

      breaks:      false
      gfm:         true
      pedantic:    false
      sanitize:    true
      smartLists:  true
      smartypants: false
      tables:      true

  (req, res, next) ->
    {pathname} = (url.parse req.url, true, true)

    # Only process markdown files
    unless /\.md$/.test pathname
      return next()

    path = pathname.replace /^\//, ''

    fs.exists path, (exists) ->
      return next() unless exists

      now = new Date().toUTCString()
      res.setHeader 'Content-Type',  'text/html; charset=UTF-8'
      res.setHeader 'Cache-Control', 'public, max-age=' + (maxAge / 1000) unless res.getHeader 'Cache-Control'
      res.setHeader 'Date',          now unless res.getHeader 'Date'
      res.setHeader 'Last-Modified', now unless res.getHeader 'Last-Modified'

      if req.method == 'HEAD'
        res.writeHead 200
        return res.end()

      if req.method != 'GET'
        return next()

      fs.readFile path, 'utf-8', (err, data) ->
        throw err if err?

        res.writeHead 200
        res.end """
          <html>
            <head>
              <title>#{path}</title>
              <style>
              #{css}
              </style>
            </head>
            <body>
            #{marked data}
            </body>
          </html>
          """

# Generic connect compatible middleware to server client code.
export default markdown = (opts = {}) ->
  md = new Markdown opts

  # Wrap with a named function for easier debugging.
  `function markdown(req, res, next) { return md.middleware(req, res, next); };`
