import json
import socket

try:
    import vim
except ImportError:
    pass


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
        res = json.loads(res)
        if res.get('result'):
            return res['result']

    def close(self):
        self.socket.close()


def underscore_to_camelcase(value):
    '''
    Converts underscore method name to CamelCase.
    '''
    def camelcase():
        yield str.lower
        while True:
            yield str.capitalize

    c = camelcase()
    return "".join(c.next()(x) if x else '_' for x in value.split("_"))


def complete(obj):
    '''
    Returns completions for a given object.
    '''
    client = Client()
    client.send(json.dumps({'evt': 'complete', 'msg': obj}))
    result = client.recv()
    client.close()
    print result


def eval_js(*args):
    '''
    Sends code to Bebop, which will be run in browser.
    '''
    code = ' '.join(args)
    client = Client()
    client.send(json.dumps({'evt': 'eval', 'msg': code}))
    result = client.recv()
    client.close()
    print result


def eval_line():
    '''
    Send current line to Bebop.
    '''
    return eval_js(vim.current.line)


def eval_range():
    '''
    Sends range to Bebop.
    '''
    r = vim.current.range
    return eval_js('\n'.join(vim.current.buffer[r.start:r.end+1]))


def eval_buffer():
    '''
    Send current buffer to Bebop.
    '''
    return eval_js('\n'.join(vim.current.buffer))
