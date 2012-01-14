from django.core.management.base import BaseCommand, CommandError
from django.core.handlers.wsgi import WSGIHandler
from django.conf import settings
from bebop.server import run


class Command(BaseCommand):
    def handle(self, *args, **kwargs):
        self.stdout.write('Running reloader\n')
        host = getattr(settings, 'BEBOP_WEBSOCKET_HOST', '127.0.0.1')
        port = getattr(settings, 'BEBOP_WEBSOCKET_PORT', '9000')
        paths = getattr(settings, 'BEBOP_WEBSOCKET_PATHS', settings.TEMPLATE_DIRS + settings.STATICFILES_DIRS)
        run(host, port, paths)
