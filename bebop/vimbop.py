import json
import re
import socket

try:
    import vim
except ImportError:
    pass


IDENTIFIER_REGEX = re.compile(r'[$a-zA-Z_][()0-9a-zA-Z_$.\'"]*')

class Client(object):
    def __init__(self, host='127.0.0.1', port=9128):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((host, port))
        self.socket.settimeout(5)

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


def complete(base):
    '''
    Returns completions for Vim.
    '''
    base = base or ''
    col = int(vim.eval("col('.')"))
    line = vim.eval("getline('.')")

    try:
        obj = IDENTIFIER_REGEX.findall(line[:col])[-1][:-(len(base)+1)]
    except IndexError:
        return '[]'

    client = Client()
    client.send(json.dumps({'evt': 'complete', 'msg': obj}))
    result = client.recv()
    client.close()
    if result:
        return repr(sorted((str(x) for x in result if base.lower() in x.lower()), key=lambda x: x.startswith(base)))
    else:
        return '[]'


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
