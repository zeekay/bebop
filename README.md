Bebop
=====
A tool for rapid web development which serves as static file server, websocket server for client-side reloading/bi-directional communcation and file watcher.

Usage
-----
Check `bebop --help` for usage.

Installation
------------
To take advantage of the client-side reloading you need a WebSocket enabled browser and a bit of javascript. You can use the provided Django middleware:

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
