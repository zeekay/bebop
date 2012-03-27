import json
import uuid
from autobahn.websocket import WebSocketServerFactory, WebSocketServerProtocol, listenWS
from datetime import datetime


class BebopWebSocketServer(WebSocketServerProtocol):
    def onOpen(self):
        self.factory.register(self)

    def onMessage(self, msg, binary):
        data = json.loads(msg)
        if data['evt'] in ('complete', 'eval'):
            self.factory.bebop_server.server.sendLine(msg)
        elif data['evt'] == 'connected':
            [c for c in self.factory.clients if c['client'] == self][0]['identifier'] = data['identifier']

    def connectionLost(self, reason):
        WebSocketServerProtocol.connectionLost(self, reason)
        self.factory.unregister(self)


class BebopWebSocketFactory(WebSocketServerFactory):
    protocol = BebopWebSocketServer

    def __init__(self, url):
        WebSocketServerFactory.__init__(self, url)
        self.clients = []

    def register(self, client):
        if not client in [c['client'] for c in self.clients]:
            for c in self.clients:
                c['active'] = ' '

            self.clients.append({
                'client': client,
                'id': str(uuid.uuid4()),
                'started': datetime.now(),
                'identifier': '',
                'active': '*'
             })

    def unregister(self, client):
        if client in [c['client'] for c in self.clients]:
            self.clients = [c for c in self.clients if not c['client'] == client]

    def attach_server(self, server):
        self.bebop_server = server


def run_websocket(host='127.0.0.1', port=1983):
    '''
    Run websocket server.
    '''
    factory = BebopWebSocketFactory("ws://%s:%s" % (host, port))
    listenWS(factory)
    return factory
