import querystring from 'querystring'

export isBrowser = do -> window?

export location = do ->
  if isBrowser
    window.location
  else
    protocol: 'http:'
    hostname: 'localhost'
    port:     '3333'

export root = do ->
  if isBrowser
    window
  else
    global

random = ->
  (((1 + Math.random()) * 0x100000) | 0).toString(16)

export urlRandomize = (url) ->
  [path, query] = url.split '?'

  unless query?
    return path + '?bop=' + random()

  query = querystring.parse query
  query.bop = random()
  path + '?' + querystring.stringify query
