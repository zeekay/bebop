import uuid
from autobahn.websocket import WebSocketServerFactory, WebSocketServerProtocol, listenWS
from datetime import datetime


class BebopWebSocketClient(WebSocketServerProtocol):
    '''
    An individual WebSocket client
    '''
    def onOpen(self):
        self.factory.register(self)

    def onMessage(self, msg, binary):
        self.factory.bebop_server.client.onMessage(self, msg)

    def connectionLost(self, reason):
        WebSocketServerProtocol.connectionLost(self, reason)
        self.factory.unregister(self)


class BebopWebSocketServer(WebSocketServerFactory):
    protocol = BebopWebSocketClient

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

    def attach_server(self, bebop_server):
        self.bebop_server = bebop_server


def run_websocket(host='127.0.0.1', port=1983):
    '''
    Run websocket server.
    '''
    websocket_server = BebopWebSocketServer("ws://%s:%s" % (host, port))
    listenWS(websocket_server)
    return websocket_server
