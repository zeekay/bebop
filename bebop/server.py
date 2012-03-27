import json
from datetime import datetime

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
        self.active_client = None

    def connectionMade(self):
        log.msg('Repl client connected')

    def dataReceived(self, data):
        msg = json.loads(data)
        if msg['evt'] in dir(self):
            getattr(self, msg['evt'])(msg)
        else:
            if self.websocket.clients:
                if self.active_client and self.active_client.get('client', None):
                    self.active_client['client'].sendMessage(data)
                else:
                    self.websocket.clients[-1]['client'].sendMessage(data)

    def active(self, msg):
        query = msg['msg'].lower()
        try:
            idx = int(query)
            self.active_client = self.websocket.clients[idx-1]
        except IndexError:
            return
        except ValueError:
            for c in self.websocket.clients:
                if query in c['identifier'].lower():
                    self.active_client = c

        for c in self.websocket.clients:
            if c['client'] == self.active_client['client']:
                c['active'] = '*'
            else:
                c['active'] = ' '

    def listeners(self, msg):
        clients = []
        for idx, c in enumerate(self.websocket.clients, start=1):
            clients.append((str(idx), c['active'], str(datetime.now() - c['started']).rsplit('.')[0], c['identifier']))

        self.sendLine(json.dumps({
            'evt': 'listeners',
            'result': '\n'.join(' - '.join(c) for c in clients)
        }))


class BebopServerFactory(Factory):
    protocol = BebopServer

    def __init__(self, websocket):
        self.websocket = websocket

    def buildProtocol(self, addr):
        self.server = BebopServer(self.websocket)
        return self.server


def run_server(websocket, host='127.0.0.1', port=1985):
    '''
    Runs TCP server, which allows clients to connect to Bebop.
    '''
    endpoint = TCP4ServerEndpoint(reactor, port, interface=host)
    bebop_server = BebopServerFactory(websocket)
    endpoint.listen(bebop_server)
    return bebop_server
