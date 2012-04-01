import json
import socket

class BebopException(Exception):
    pass

class Client(object):
    '''
    Client object for communicating with Bebop's TCP interface.
    '''
    def __init__(self):
        self.socket = None

    def connect(self, host='127.0.0.1', port=1985):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((host, port))
        self.socket.settimeout(1)

    def send(self, data):
        '''
        Send JSON message to Bebop
        '''
        self.socket.sendall(json.dumps(data))

    def recv(self):
        '''
        Recieve response from Bebop.
        '''
        res = ''
        while True:
            data = self.socket.recv(1024)
            if '\r\n' in data:
                res += data
                break
            res += data
        res = json.loads(res)

        if res.get('result'):
            return res['result']
        elif res.get('error'):
            raise BebopException(res['error'])

    def close(self):
        '''
        Close connection to Bebop.
        '''
        if self.socket:
            self.socket.close()

    def eval(self, code):
        '''
        Send code to Bebop, which will be eval'd by WebSocket client(s).
        '''
        self.send({'evt': 'eval', 'msg': code})
        result = self.recv()
        return result

    def complete(self, obj):
        '''
        Ask active WebSocket client to return a list of properties for a givent object.
        '''
        self.send({'evt': 'complete', 'msg': obj})
        result = self.recv()
        return result

    def modified(self, file=''):
        '''
        Notify WebSocket clients that a file has been modified.
        '''
        self.send({'evt': 'modified', 'msg': file})

    def list_websocket_clients(self):
        '''
        List WebSocket clients.
        '''
        self.send({'evt': 'list_websocket_clients'})
        result = self.recv()
        return result

    def set_active_client(self, listener):
        '''
        Set active WebSocket client.
        '''
        self.send({'evt': 'set_active_client', 'msg': listener})

    def toggle_broadcast(self):
        '''
        Toggle broadcast on/off.
        '''
        self.send({'evt': 'toggle_broadcast'})
