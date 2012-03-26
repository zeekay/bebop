import json

from autobahn.websocket import WebSocketServerFactory, WebSocketServerProtocol, listenWS

class BebopWebSocketServer(WebSocketServerProtocol):
    def onOpen(self):
        self.factory.register(self)

    def onMessage(self, msg, binary):
        data = json.loads(msg)
        if data['evt'] in ('complete', 'eval'):
            self.factory.bebop_server.server.sendLine(msg)

    def connectionLost(self, reason):
        WebSocketServerProtocol.connectionLost(self, reason)
        self.factory.unregister(self)


class BebopWebSocketFactory(WebSocketServerFactory):
    protocol = BebopWebSocketServer

    def __init__(self, url):
        WebSocketServerFactory.__init__(self, url)
        self.clients = []

    def register(self, client):
        if not client in self.clients:
            self.clients.append(client)

    def unregister(self, client):
        if client in self.clients:
            self.clients.remove(client)

    def attach_server(self, server):
        self.bebop_server = server


def run_websocket(host='127.0.0.1', port=1983):
    '''
    Run websocket server.
    '''
    factory = BebopWebSocketFactory("ws://%s:%s" % (host, port))
    listenWS(factory)
    return factory
