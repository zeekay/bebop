# Automatically redirect to root /node_modules handler
export default nodeModulesRedirect = (req, res, next) ->
  nm = req.path.indexOf 'node_modules'
  if ~nm
    res.writeHead 301, Location: "/#{req.path.substr nm}"
    res.end()
  else
    next()

