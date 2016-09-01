querystring = require 'querystring'

exports.root = do ->
  if typeof window is 'undefined'
    root = global
  else
    root = window
    root.isBrowser = true

  root.location ?=
    protocol: 'http:'
    hostname: 'localhost'
    port:     '3333'

  root

random = ->
  (((1 + Math.random()) * 0x100000) | 0).toString(16)

exports.urlRandomize = (url) ->
  [path, query] = url.split '?'

  unless query?
    return path + '?bop=' + random()

  query = querystring.parse query
  query.bop = random()
  path + '?' + querystring.stringify query
