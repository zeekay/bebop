import json
import os

from twisted.python import log
from twisted.internet import reactor

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from watchdog.utils.platform import is_darwin


class ReloadHandler(FileSystemEventHandler):
    '''
    File system watcher which detcts when files have changed and reloads server.
    '''
    def __init__(self, factory):
        super(ReloadHandler, self).__init__()
        self.factory = factory

    def on_modified(self, event):
        if is_darwin():
            # on_modified event is fired off for both the directory modified and actual file
            if event.is_directory:
                modified_files = [os.path.join(event.src_path, f) for f in next(os.walk(event.src_path))[2]]
                mod_file = max(modified_files, key=os.path.getmtime)
                log.msg('Modified %s' % mod_file)
                self.msg_clients(mod_file)
            else:
                log.msg('Modified %s' % event.src_path)
                self.msg_clients(event.src_path)
        else:
            if os.path.exists(event.src_path):
                log.msg('Modified %s' % event.src_path)
                self.msg_clients(event.src_path)


    def msg_clients(self, path):
        '''
        Notifies clients connected that a file has changed.
        '''
        path = path.replace(os.getcwd(), '')
        for c in self.factory.clients:
            c = c['client']
            log.msg('Reloading %s' % c.peerstr)
            reactor.callFromThread(c.sendMessage, json.dumps({'evt': 'modified', 'msg': path}))


def run_watcher(factory, paths, recursive=True):
    '''
    Run file system watcher.
    '''
    event_handler = ReloadHandler(factory)
    watcher = Observer()
    for path in paths:
        watcher.schedule(event_handler, path=path, recursive=recursive)
    watcher.start()
