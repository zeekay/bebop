import json
import os

from twisted.python import log
from twisted.protocols import basic
from twisted.internet import reactor
from twisted.internet.protocol import Factory
from twisted.internet.endpoints import TCP4ServerEndpoint

from autobahn.websocket import WebSocketServerFactory, WebSocketServerProtocol, listenWS

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from watchdog.utils.platform import is_darwin


class ReloadHandler(FileSystemEventHandler):
    '''
    Event handler which detects when files have changed and reloads server.
    '''
    def __init__(self, factory):
        super(ReloadHandler, self).__init__()
        self.factory = factory

    def on_modified(self, event):
        if is_darwin():
            # on_modified event is fired off for both the directory modified and actual file
            if event.is_directory:
                modified_files = [os.path.join(event.src_path, f) for f in next(os.walk(event.src_path))[2]]
                mod_file = max(modified_files, key=os.path.getmtime)
                log.msg('Modified %s' % mod_file)
                self.msg_clients(mod_file)
            else:
                log.msg('Modified %s' % event.src_path)
                self.msg_clients(event.src_path)
        else:
            if os.path.exists(event.src_path):
                log.msg('Modified %s' % event.src_path)
                self.msg_clients(event.src_path)


    def msg_clients(self, path):
        '''
        Notifies clients connected that a file has changed.
        '''
        path = path.replace(os.getcwd(), '')
        for c in self.factory.clients:
            log.msg('Reloading %s' % c.peerstr)
            reactor.callFromThread(c.sendMessage, json.dumps({'evt': 'modified', 'msg': path}))


class BebopServerProtocol(WebSocketServerProtocol):
    '''
    WebSocket server protocol.
    '''
    def onOpen(self):
        self.factory.register(self)

    def onMessage(self, msg, binary):
        data = json.loads(msg)
        if data['evt'] in ('complete', 'eval'):
            self.factory.eval_server.server.sendLine(msg)

    def connectionLost(self, reason):
        WebSocketServerProtocol.connectionLost(self, reason)
        self.factory.unregister(self)


class BebopServerFactory(WebSocketServerFactory):
    '''
    WebSocket server.
    '''
    protocol = BebopServerProtocol

    def __init__(self, url):
        WebSocketServerFactory.__init__(self, url)
        self.clients = []
        self.eval_conn = None

    def register(self, client):
        if not client in self.clients:
            self.clients.append(client)

    def unregister(self, client):
        if client in self.clients:
            self.clients.remove(client)

    def attach_eval(self, server):
        self.eval_server = server


class EvalServer(basic.LineReceiver):
    '''
    Protocol for doing browser-side evaluation of javascript.
    '''
    def __init__(self, websocket):
        self.websocket = websocket

    def connectionMade(self):
        log.msg('Repl client connected')

    def dataReceived(self, data):
        msg = json.loads(data)
        if msg['evt'] in dir(self):
            getattr(self, msg['evt'])(msg)
        else:
            for c in self.websocket.clients:
                c.sendMessage(data)

    def listeners(self, msg):
        self.sendLine(json.dumps({'evt': 'listeners', 'result': [str(x) for x in self.websocket.clients]}))


class EvalServerFactory(Factory):
    protocol = EvalServer

    def __init__(self, websocket):
        self.websocket = websocket

    def buildProtocol(self, addr):
        self.server = EvalServer(self.websocket)
        return self.server


def run_eval(websocket, host='127.0.0.1', port=9128):
    '''
    Runs eval server for browser-side evaluation.
    '''
    endpoint = TCP4ServerEndpoint(reactor, port, interface=host)
    eval_server = EvalServerFactory(websocket)
    endpoint.listen(eval_server)
    return eval_server


def run_static(host='127.0.0.1', port=8000, paths=None):
    '''
    Run static file server, useful for local development.
    '''
    from twisted.web import static, server

    if not paths:
        paths = ['.']

    for path in paths:
        root = static.File(os.path.abspath(path))
    reactor.listenTCP(port, server.Site(root), interface=host)


def run_websocket(host='127.0.0.1', port=9000):
    '''
    Run websocket server.
    '''
    factory = BebopServerFactory("ws://%s:%s" % (host, port))
    listenWS(factory)
    return factory


def run_watcher(factory, paths, recursive=True):
    '''
    Run file system watcher.
    '''
    event_handler = ReloadHandler(factory)
    watcher = Observer()
    for path in paths:
        watcher.schedule(event_handler, path=path, recursive=recursive)
    watcher.start()
