import json

from twisted.python import log
from twisted.protocols import basic
from twisted.internet import reactor
from twisted.internet.protocol import Factory
from twisted.internet.endpoints import TCP4ServerEndpoint


class BebopServer(basic.LineReceiver):
    '''
    TCP server which clients connect to, allowing them to evaluate and introspect Javascript using connected browsers/servers.
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


class BebopServerFactory(Factory):
    protocol = BebopServer

    def __init__(self, websocket):
        self.websocket = websocket

    def buildProtocol(self, addr):
        self.server = BebopServer(self.websocket)
        return self.server


def run_server(websocket, host='127.0.0.1', port=9128):
    '''
    Runs TCP server, which allows clients to connect to Bebop.
    '''
    endpoint = TCP4ServerEndpoint(reactor, port, interface=host)
    bebop_server = BebopServerFactory(websocket)
    endpoint.listen(bebop_server)
    return bebop_server
