import json
import socket

class Client(object):
    def __init__(self, host='127.0.0.1', port=9128):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((host, port))

    def send(self, data):
        self.socket.sendall(data)

    def recv(self):
        res = ''
        while True:
            data = self.socket.recv(1024)
            if '\r\n' in data:
                res += data
                break
            res += data
        return json.loads(res)['result']

    def close(self):
        self.socket.close()

def eval_line(line):
    client = Client()
    client.send(line)
    res = client.recv()
    client.close()
    return res
