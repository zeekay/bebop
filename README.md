# Bebop
A tool for rapid web development which bundles a static file server, file
watcher, WebSocket server for automatically reloading assets and interfacing
with browser/server Javascript applications.

## Installation

```sh
$ npm install -g bebop
```

If you use bebop's static file serving feature it will automatically inject the
Javascript required. If you want to enable something similar for your own
connec/express apps you can use `bebop.middleware`, or link directly to
`bebop-client/bebop.js`.

## Usage
Change to the directory in which your application resides and run `bebop`.

```sh
$ cd ~/myapp
$ bebop
```

Check `bebop --help` for various options/configuration.

## Configuration
You can configure Bebop by creating a `.bebop<.js/coffee>` file in either your
home directory or the root of your project. Properties exported in this module
will be used to override the defaults used.

## Vim
Integration with vim is provided by
[vim-bebop](http://github.com/zeekay/vim-bebop). You can do all sorts of fancy
stuff like evaluate Javascript, Coffeescript, get completions, etc.
