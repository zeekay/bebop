import os
from twisted.internet import protocol
from twisted.internet import reactor
from twisted.internet import stdio
from twisted.protocols import basic


class NodeRepl(basic.LineReceiver):
    delimiter = '\n'

    def __init__(self, node):
        self.node = node

    def lineReceived(self, line):
        self.node.transport.write(line)


class NodeClient(protocol.ProcessProtocol):
    def connectionMade(self):
        print "Connected to node."

    def outReceived(self, data):
        print data

    def errReceived(self, data):
        print data

    def outConnectionLost(self):
        print "Connection to node lost!"
        self.transport.signalProcess('KILL')

    def processEnded(self, reason):
        run_node()

def run_node():
    process = NodeClient()
    stdio.StandardIO(NodeRepl(process))
    reactor.spawnProcess(process, 'bebop-client', ['bebop-client'], env=os.environ, usePTY=False)
