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

exports.urlRandomize = (url) ->
  url = url.replace(/[?&]bebop=\w+/, '')
  url += (if (url.indexOf('?') is -1) then '?' else '&')
  url + 'bebop=' + (((1 + Math.random()) * 0x100000) | 0).toString(16)
