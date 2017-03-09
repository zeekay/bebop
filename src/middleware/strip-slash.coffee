trailingSlashRe = /\.html\/$/  # Slash erroneously appended to path name

# Detect odd bug with some browsers and redirect
export default stripSlash = (req, res, next) ->
  unless trailingSlashRe.test req.url
    return next()
  loc = req.url.replace trailingSlashRe, '.html'
  res.redirect loc

