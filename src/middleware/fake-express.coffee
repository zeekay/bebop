# Connect is fairly minimal, flesh out req, res with a few helper
# methods/properties. Required for compatibility with non-standard connect
# middleware which expects various express conventions.
export default (req, res, next) ->
  # Slim stand-ins for what you get with Express
  res.redirect = (loc) ->
    res.writeHead 302, Location: loc
    res.end()

  res.set = (headers) ->
    for k,v of headers
      res.setHeader k, v

  res.send = (body) ->
    res.end body

  # Convenient for our middleware later
  url = url.parse req.url
  req.path   = url.pathname
  req.search = url.search
  next()
