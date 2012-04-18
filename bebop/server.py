import json
from datetime import datetime

from twisted.python import log
from twisted.protocols import basic
from twisted.internet import reactor
from twisted.internet.protocol import Factory
from twisted.internet.endpoints import TCP4ServerEndpoint


class BebopClient(basic.LineReceiver):
    '''
    A Bebop client which connects TCP. Bebop clients communicate with WebSocketClients allowing them to evaluate and introspect Javascript using connected browsers/servers.
    '''
    def __init__(self, websocket_server):
        self.websocket_server = websocket_server
        self.broadcast = False

    def connectionMade(self):
        log.msg('Client connected')

    def dataReceived(self, data):
        '''
        Handle data recieved from a Bebop client.
        '''
        msg = json.loads(data)
        if msg['evt'] in dir(self):
            getattr(self, msg['evt'])(msg)
        else:
            if self.websocket_server.clients:
                if self.broadcast:
                    for c in self.websocket_server.clients:
                        c['client'].sendMessage(data)
                else:
                    if self.active_client and self.active_client.get('client', None):
                        self.active_client['client'].sendMessage(data)
                    else:
                        self.websocket_server.clients[-1]['client'].sendMessage(data)
            else:
                self.sendLine(json.dumps({'error': 'No WebSocket clients connected'}))

    def onMessage(self, client, msg):
        '''
        Data recieved from a WebSocket endpoint.
        '''
        data = json.loads(msg)
        if data['evt'] in ('complete', 'eval'):
            if self.active_client:
                if client == self.active_client['client']:
                    self.sendLine(msg)
        elif data['evt'] == 'connected':
            [c for c in self.websocket_server.clients if c['client'] == client][0]['identifier'] = data['identifier']

    @property
    def active_client(self):
        '''
        Returns currently active client.
        '''
        for c in self.websocket_server.clients:
            if c['active'] == '*':
                return c

    def toggle_broadcast(self, msg):
        '''
        Toggles sending messages to all WebSocket endpoints.
        '''
        self.broadcast = not self.broadcast

    def set_active_client(self, msg):
        '''
        Set websocket client as active.
        '''
        query = msg['msg'].lower()
        try:
            idx = int(query)
            self.active_client = self.websocket_server.clients[idx-1]
        except IndexError:
            return
        except ValueError:
            for c in self.websocket_server.clients:
                if query in c['identifier'].lower():
                    self.active_client = c

        for c in self.websocket_server.clients:
            if c['client'] == self.active_client['client']:
                c['active'] = '*'
            else:
                c['active'] = ' '

    def list_websocket_clients(self, msg):
        '''
        List WebSocket clients
        '''
        clients = []
        for idx, c in enumerate(self.websocket_server.clients, start=1):
            clients.append((str(idx), c['active'], str(datetime.now() - c['started']).rsplit('.')[0], c['identifier']))

        self.sendLine(json.dumps({
            'evt': 'listeners',
            'result': '\n'.join(' - '.join(c) for c in clients)
        }))


class BebopServer(Factory):
    '''
    Factory for BebopClients, at the moment only one client can be active at a time.
    '''

    protocol = BebopClient

    def __init__(self, websocket_server):
        self.websocket_server = websocket_server
        self.client = BebopClient(self.websocket_server)

    def buildProtocol(self, addr):
        self.client = BebopClient(self.websocket_server)
        return self.client


def run_server(websocket_server, host='127.0.0.1', port=1985):
    '''
    Runs TCP server, which allows clients to connect to Bebop.
    '''
    endpoint = TCP4ServerEndpoint(reactor, port, interface=host)
    bebop_server = BebopServer(websocket_server)
    endpoint.listen(bebop_server)
    return bebop_server
