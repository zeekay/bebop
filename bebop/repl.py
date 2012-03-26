import json

from twisted.internet import stdio, reactor
from twisted.protocols import basic
from twisted.internet.protocol import ClientFactory


class Repl(basic.LineReceiver):
    delimiter = '\n'
    prompt_string = '> '

    def prompt(self):
        self.transport.write(self.prompt_string)

    def connectionMade(self):
        self.client_factory = EvalClientFactory(self)
        reactor.connectTCP('127.0.0.1', 1985, self.client_factory)

    def lineReceived(self, line):
        if not line:
            self.prompt()
            return
        self.client_factory.client.sendLine(json.dumps({'evt': 'eval', 'msg': line}))


class EvalClient(basic.LineReceiver):
    def __init__(self, repl):
        self.repl = repl

    def dataReceived(self, data):
        data = json.loads(data)
        res = data.get('result')
        if res:
            for line in str(res).splitlines():
                self.repl.sendLine(line)
        self.repl.prompt()


class EvalClientFactory(ClientFactory):
    def __init__(self, repl):
        self.repl = repl
        self.client = None

    def buildProtocol(self, addr):
        print 'Connected to Bebop'
        self.repl.prompt()
        self.client = EvalClient(self.repl)
        return self.client

    def clientConnectionLost(self, connector, reason):
        print 'Lost connection.  Reason:', reason
        reactor.stop()

    def clientConnectionFailed(self, connector, reason):
        print 'Connection failed. Reason:', reason
        reactor.stop()


def run_repl():
    '''
    Run interactive repl client
    '''
    stdio.StandardIO(Repl())
    reactor.run()
