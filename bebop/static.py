import os

from twisted.internet import reactor
from twisted.web import resource
from twisted.web.server import Site
from twisted.web.static import File


class BebopIndex(resource.Resource):
    '''
    Injects bebop.js into index pages when using static file server.
    '''
    def __init__(self, filename, registry=None):
        self.filename = filename

    def render(self, request):
        with open(self.filename) as f:
            content = f.read()
        try:
            index = content.index('</body>')
        except ValueError:
            return content
        return ''.join((content[:index], '<script src="/_bebop/bebop.js" type="text/javascript"></script>', content[index:]))


def run_static(host='127.0.0.1', port=8000, path='.', inject=True):
    '''
    Run static file server, useful for local development, can also automatically
    inject bebop.js into index pages.
    '''
    root = File(os.path.abspath(path))
    root_dir = os.path.abspath(os.path.dirname(__file__))

    if inject:
        root.putChild('_bebop', File(os.path.join(root_dir, '../lib')))
        root.indexNames=['index.html','index.htm']
        root.processors = {
            '.html': BebopIndex,
            '.htm': BebopIndex,
        }
    factory = Site(root)
    reactor.listenTCP(port, factory, interface=host)
