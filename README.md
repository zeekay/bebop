Bebop
=====
A tool for rapid web development which bundles a static file server, file watcher, WebSocket server for automatically reloading assets and interfacing with browser/server Javascript applications.

Usage
-----
Check `bebop --help` for usage.

Installation
------------
To install the server components use `pip`.

    pip install bebop-server

To install the node.js client use `npm`.

    npm install -g bebop

If you use bebop's static file server feature it will automatically inject the Javascript required for it to connect back to bebop.

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
Integration with vim is provided by [vim-bebop](http://github.com/zeekay/vim-bebop). You can do all sorts of fancy stuff like evaluate Javascript, Coffeescript, get completions, etc.
