fs = require 'fs'
url = require 'url'
marked = require 'marked'

module.exports = (opts = {}) ->
  maxAge = opts.maxAge or 0

  marked.setOptions
    renderer: new marked.Renderer()
    gfm: true
    tables: true
    breaks: false
    pedantic: false
    sanitize: true
    smartLists: true
    smartypants: false

  css = fs.readFileSync __dirname +  '/../assets/github-markdown.css', 'utf-8'

  (req, res, next) ->
    {pathname} = (url.parse req.url, true, true)

    # only process markdown files
    unless /\.md$/.test pathname
      return next()

    path = pathname.replace /^\//, ''

    fs.exists path, (exists) ->
      unless exists
        return next()

      now = new Date().toUTCString()
      res.setHeader 'Date', now unless res.getHeader 'Date'
      res.setHeader 'Cache-Control', 'public, max-age=' + (maxAge / 1000) unless res.getHeader 'Cache-Control'
      res.setHeader 'Last-Modified', now unless res.getHeader 'Last-Modified'
      res.setHeader 'Content-Type', 'text/html; charset=UTF-8'

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
