import json
import socket


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
        self.socket.sendall(json.dumps(data))

    def recv(self):
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

    def close(self):
        '''
        Close connection to Bebop.
        '''
        if self.socket:
            self.socket.close()

    def eval(self, code):
        '''
        Sends code to Bebop, which will be run in browser.
        '''
        self.send({'evt': 'eval', 'msg': code})
        result = self.recv()
        return result

    def complete(self, obj):
        '''
        Asks bebop to return a list of properties on a given object.
        '''
        self.send({'evt': 'complete', 'msg': obj})
        result = self.recv()
        return result

    def modified(self, path=''):
        '''
        Sends modified event to bebop.
        '''
        self.send({'evt': 'modified', 'msg': path})

    def listeners(self):
        '''
        List listeners connected to Bebop.
        '''
        self.send({'evt': 'listeners'})
        result = self.recv()
        return result

    def active(self, listener):
        '''
        Makes bebop forward message to given listeners.
        '''
        self.send({'evt': 'active', 'msg': listener})

    def sync(self):
        '''
        Toggles Bebop's sync feature.
        '''
        self.send({'evt': 'sync'})
