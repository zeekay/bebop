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

...or simply link to [bebop.js](https://raw.github.com/zeekay/bebop/master/bebop/bebop.js) in your project:

    <script src="https://raw.github.com/zeekay/bebop/master/bebop/bebop.js" type="text/javascript"></script>

Vim
---
Integration with vim is provided by [vim-bebop](http://github.com/zeekay/vim-bebop). You can do all sorts of fancy stuff like evaluate JavaScript, CoffeeScript, get completions, etc.
