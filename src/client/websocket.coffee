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

WebSocket = root.WebSocket ? root.MozWebSocket ? fallback()

if root.isBrowser
  WebSocket.identifier = location.href + ' - ' + navigator.userAgent
else
  WebSocket.identifier = process.argv[1] + ' - node'

module.exports = WebSocket
