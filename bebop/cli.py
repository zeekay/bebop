from bebop.repl import run_repl
from bebop.server import run_eval, run_static, run_websocket, run_watcher

from twisted.internet import reactor

def run(args):
    '''
    Launch bebop with arguments passed from command line.
    '''

    # launch REPL
    if args.repl:
        return run_repl()

    # start websocket server
    factory = run_websocket(args.websocket_host, args.websocket_port)

    # start file watcher
    reactor.callInThread(run_watcher, factory, args.watch_paths, args.not_recursive)

    # start eval tcp client server
    eval_server = run_eval(factory)
    factory.attach_eval(eval_server)

    # start static file server
    if not args.no_static:
        run_static(args.static_host, args.static_port, args.static_paths)

    # run reactor, run!
    reactor.run()
