import argparse
import sys
import webbrowser
from bebop.repl import run_repl
from bebop.server import run_server
from bebop.websocket import run_websocket
from bebop.static import run_static
from bebop.watcher import run_watcher
from twisted.internet import reactor
from twisted.python import log


def run():
    '''
    Launch bebop with arguments passed from command line.
    '''

    parser = argparse.ArgumentParser(description='Bebop Development Server')
    parser.add_argument('-w', '--watch-paths', default='.', nargs='+', help="Directories to watch")
    parser.add_argument('-n', '--not-recursive', default=True, action='store_false', help="Don't watch recursively")
    parser.add_argument('-s', '--static-path', default='.', help="Directory to serve from")

    parser.add_argument('-b', '--websocket-host', default='0.0.0.0')
    parser.add_argument('-p', '--websocket-port', '-p', default=1983, type=int)

    parser.add_argument('--static-host', default='0.0.0.0')
    parser.add_argument('--static-port', default=8000, type=int)

    parser.add_argument('-r', '--repl', action='store_true', help='Open REPL')

    parser.add_argument('--no-inject', default=True, action='store_false', help="Do not inject bebop.js into index pages")
    parser.add_argument('--no-watcher', action='store_true', help="Don't watch for changes")
    parser.add_argument('--no-static', action='store_true', help="Don't serve static files")
    parser.add_argument('--no-server', action='store_true', help="Don't run TCP client server")
    parser.add_argument('--no-open-browser', action='store_true', help="Don't open webbrowser automatically")

    args = parser.parse_args()
    log.startLogging(sys.stdout)

    # launch REPL
    if args.repl:
        return run_repl()

    # start websocket server
    factory = run_websocket(args.websocket_host, args.websocket_port)

    # start file watcher
    if not args.no_watcher:
        reactor.callInThread(run_watcher, factory, args.watch_paths, args.not_recursive)

    # start TCP client server
    if not args.no_server:
        server = run_server(factory)
        factory.attach_server(server)

    # start static file server
    if not args.no_static:
        run_static(args.static_host, args.static_port, args.static_path, args.no_inject)

        # open browser automatically
        if not args.no_open_browser:
            webbrowser.open('http://%s:%s' % (args.static_host, args.static_port))

    # run reactor, run!
    reactor.run()
