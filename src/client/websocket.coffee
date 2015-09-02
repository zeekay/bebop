{root} = require './utils'
{load} = require './node'

root.WEB_SOCKET_SWF_LOCATION = 'https://cdnjs.cloudflare.com/ajax/libs/web-socket-js/1.0.0/WebSocketMain.swf'
urls = [
  'https://cdnjs.cloudflare.com/ajax/libs/web-socket-js/1.0.0/web_socket.js'
  'https://cdnjs.cloudflare.com/ajax/libs/web-socket-js/1.0.0/web_socket.min.js'
]

fallback = ->
  load url for url in urls
  root.WebSocket

_WebSocket = root.WebSocket ? root.MozWebSocket ? fallback()

module.exports = class WebSocket extends _WebSocket
  constructor: (address) ->
    super

    if root.isBrowser
      @identifier = location.href + ' - ' + navigator.userAgent
    else
      @identifier = process.argv[1] + ' - node'

    if root.isBrowser
      root.addEventListener 'beforeunload', => @close()
