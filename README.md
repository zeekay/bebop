# Bebop
A tool for rapid web development which bundles a static file server, file
watcher, WebSocket server for automatically reloading assets and interfacing
with browser/server Javascript applications.

## Installation

```sh
$ npm install -g bebop
```

If you use bebop's static file serving feature it will automatically inject the
Javascript required, otherwise you can link directly to `lib/client.js` in your
application code.

```javascript
// bebop.js -> lib/client.js
<script src="bebop.js" type="text/javascript"></script>
```

## Usage
Change to the directory in which your application resides and run `bebop`.

```sh
$ cd ~/myapp
$ bebop
```

Check `bebop --help` for various options/configuration.

## Vim
Integration with vim is provided by
[vim-bebop](http://github.com/zeekay/vim-bebop). You can do all sorts of fancy
stuff like evaluate Javascript, Coffeescript, get completions, etc.
