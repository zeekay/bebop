import os
from django.conf import settings

HOST = getattr(settings, 'BEBOP_WEBSOCKET_HOST', '127.0.0.1')
PORT = getattr(settings, 'BEBOP_WEBSOCKET_PORT', '9000')
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'bebop.js')) as f:
    RELOADER_SCRIPT = ''.join(('<script type="text/javascript">', f.read(), '</script>'))

RELOADER_SCRIPT.replace('127.0.0.1', HOST)
RELOADER_SCRIPT.replace('9000', PORT)

class ReloaderMiddleware(object):
    def process_response(self, request, response):
        try:
            index = response.content.index('</body>')
            response.content = ''.join((response.content[:index], RELOADER_SCRIPT, response.content[index:]))
        except ValueError:
            pass
        return response
