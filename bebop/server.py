#!/usr/bin/env python
import argparse
import os
import sys
from twisted.internet import reactor, threads
from twisted.python import log
from autobahn.websocket import WebSocketServerFactory, WebSocketServerProtocol, listenWS
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from watchdog.utils.platform import is_darwin


class ReloadHandler(FileSystemEventHandler):
    '''
    Event handler which detects when files have changed and reloads server.
    '''
    def __init__(self, factory):
        super(ReloadHandler, self).__init__()
        self.factory = factory

    def on_modified(self, event):
        if is_darwin():
            # on_modified event is fired off for both the directory modified and actual file
            if event.is_directory:
                self.msg_clients(event.src_path)
            else:
                log.msg('Modified %s' % event.src_path)
        else:
            if os.path.exists(event.src_path):
                log.msg('Modified %s' % event.src_path)
                self.msg_clients(event.src_path)


    def msg_clients(self, path):
        '''
        Notifies clients connected that a file has changed.
        '''
        for c in self.factory.clients:
            log.msg('Reloading %s' % c.peerstr)
            c.sendMessage('Reload')
            threads.blockingCallFromThread(self.sendMessage, 'Reload')


class BebopServerProtocol(WebSocketServerProtocol):
    '''
    WebSocket web server protocol.
    '''
    def onOpen(self):
        self.factory.register(self)

    def connectionLost(self, reason):
        WebSocketServerProtocol.connectionLost(self, reason)
        self.factory.unregister(self)


class BebopServerFactory(WebSocketServerFactory):
    '''
    WebSocket web server.
    '''
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


def run_static(host='0.0.0.0', port=8000, paths=None):
    '''
    Run static file server, useful for local development.
    '''
    from twisted.web import static, server

    if not paths:
        paths = ['.']

    for path in paths:
        root = static.File(os.path.abspath(path))
    reactor.listenTCP(port, server.Site(root), interface=host)


def run_websocket(host='0.0.0.0', port=9000):
    '''
    Run websocket server.
    '''
    factory = BebopServerFactory("ws://%s:%s" % (host, port))
    listenWS(factory)
    return factory


def run_watcher(factory, paths, recursive=True):
    '''
    Run file system watcher.
    '''
    event_handler = ReloadHandler(factory)
    watcher = Observer()
    for path in paths:
        watcher.schedule(event_handler, path=path, recursive=recursive)
    watcher.start()


def run(args):
    '''
    Launch bebop with arguments passed from command line.
    '''
    factory = run_websocket(args.websocket_host, args.websocket_port)
    reactor.callInThread(run_watcher, factory, args.watch_paths, args.not_recursive)
    if args.run_static_server:
        run_static(args.static_host, args.static_port, args.static_paths)
    reactor.run()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Bebop Development Server')
    parser.add_argument('-w', '--watch-paths', default='.', nargs='+', help="Directories to watch")
    parser.add_argument('-n', '--not-recursive', default=True, action='store_false', help="Don't watch recursively")
    parser.add_argument('-s', '--static-paths', default='.', nargs='+', help="Directories to serve from")
    parser.add_argument('--static-host', default='0.0.0.0')
    parser.add_argument('--static-port', default=8000, type=int)
    parser.add_argument('-b', '--websocket-host', default='0.0.0.0')
    parser.add_argument('-p', '--websocket-port', '-p', default=9000, type=int)
    parser.add_argument('-r', '--run-static-server', action='store_true', help="Serve local static files")

    args = parser.parse_args()
    log.startLogging(sys.stdout)
    run(args)
