import argparse
import os
import sys
from twisted.internet import reactor
from twisted.python import log
from autobahn.websocket import WebSocketServerFactory, WebSocketServerProtocol, listenWS
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from watchdog.utils.platform import is_darwin


class ReloadHandler(FileSystemEventHandler):
    def __init__(self, factory):
        super(ReloadHandler, self).__init__()
        self.factory = factory

    if is_darwin():
        def on_modified(self, event):
            # on_modified event is fired off for both the directory modified and actual file
            if event.is_directory:
                for c in self.factory.clients:
                    print 'Reloading', c.peerstr
                    reactor.callFromThread(lambda: c.sendMessage('Reload'))
            else:
                print 'Modified', event.src_path
    else:
        def on_modified(self, event):
            if os.path.exists(event.src_path):
                print 'Modified', event.src_path
                for c in self.factory.clients:
                    print 'Reloading', c.peerstr
                    reactor.callFromThread(lambda: c.sendMessage('Reload'))


class BebopServerProtocol(WebSocketServerProtocol):
    def onOpen(self):
        self.factory.register(self)

    def connectionLost(self, reason):
        WebSocketServerProtocol.connectionLost(self, reason)
        self.factory.unregister(self)


class BebopServerFactory(WebSocketServerFactory):
    protocol = BebopServerProtocol

    def __init__(self, url):
        WebSocketServerFactory.__init__(self, url)
        self.clients = []

    def register(self, client):
        if not client in self.clients:
            self.clients.append(client)

    def unregister(self, client):
        if client in self.clients:
            self.clients.remove(client)


def start(host, port, paths):
    factory = BebopServerFactory("ws://%s:%s" % (host, port))
    listenWS(factory)
    event_handler = ReloadHandler(factory)
    observer = Observer()
    for path in paths:
        observer.schedule(event_handler, path=path, recursive=True)
    observer.start()


def run(host, port, paths):
    start(host, port, paths)
    reactor.run()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Bebop WebSocket Reloader')
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', '-p', default=9000, type=int)
    parser.add_argument('--watch', default='.', nargs='+')
    args = parser.parse_args()

    log.startLogging(sys.stdout)

    run(args.host, args.port, args.watch)
