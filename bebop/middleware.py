from django.conf import settings

HOST = getattr(settings, 'BEBOP_WEBSOCKET_HOST', '127.0.0.1')
PORT = getattr(settings, 'BEBOP_WEBSOCKET_PORT', '9000')
RELOADER_SCRIPT = """
<!-- Added by Bebop -->
<script type="text/javascript">
!function(){
  WebSocket = window.WebSocket || window.MozWebSocket;
  if (!WebSocket)
    return console.log('WebSocket not Supported');

  var url = 'ws://%s:%s';
  var ws = new WebSocket(url);

  ws.onopen = function() {
    console.log('Connected to Reloader');
  };

  ws.onmessage = function(evt) {
    window.location.reload();
  }

  ws.onclose = function() {
    console.log('Connection to Reloader closed');
  }
}()
</script>
""" % (HOST, PORT)


class ReloaderMiddleware(object):
    def process_response(self, request, response):
        try:
            index = response.content.index('</body>')
            response.content = ''.join((response.content[:index], RELOADER_SCRIPT, response.content[index:]))
        except ValueError:
            pass
        return response
