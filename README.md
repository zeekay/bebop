Bebop
=====
A tool for local development that comprised of a static file server, websocket server for client-side reloading and file watcher.

Usage
-----
Check `bebop --help` for usage.

Installation
------------
If you want to use the client-side reloading you need a WebSocket enabled browser and you need to add a bit of javascript so that your browser will connect to Bebop. You can use the provided Django middleware:

    INSTALLED_APPS = (
        ...,
        'bebop',
    )
    MIDDLEWARE_CLASSES = (
        ...,
        'bebop.middleware.ReloaderMiddleware',
    )

...or simply add a bit of javascript to your project:

    <script type="text/javascript">
      (function(){

        WebSocket = window.WebSocket || window.MozWebSocket;
        if (!WebSocket)
          return console.log('WebSocket not Supported');

        var ws = new WebSocket('ws://127.0.0.1:9000');

        ws.onopen = function() {
          console.log('Connected to Reloader');
        };

        ws.onmessage = function(evt) {
          window.location.reload();
        }

        ws.onclose = function() {
          console.log('Connection to Reloader closed');
        }

      }())
    </script>
