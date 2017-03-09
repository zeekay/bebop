trailingHtmlRe  = /\.html$/    # Path ends with .html


# Strip .html from paths for nicer user experience
export default stripHtml = (req, res, next) ->
  unless trailingHtmlRe.test req.url
    return next()

  loc = req.url.replace /index.html$/, ''
  loc = loc.replace trailingHtmlRe, ''
  res.redirect loc
