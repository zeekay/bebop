## Bebop
#### Code ninja, code ninja go! Develop at breakneck speeds.
Bebop is a rapid web development tool with a built-in http server, preprocessing
workflow support and intelligent browser reloading, freeing you to hit the keys
like an undead techno-zombie Charlie Parker.

### Installation

```sh
$ npm install -g bebop
```

If you use bebop's static file serving feature it will automatically inject the
Javascript required. If you want to enable something similar for your own
connec/express apps you can use `bebop.middleware`, or link directly to
`bebop-client/bebop.js`.

### Usage
Change to the directory in which your application resides and run `bebop`.

```sh
$ cd ~/myapp
$ bebop
```

Check `bebop --help` for various options/configuration.

### Configuration
You can configure Bebop by creating a `.bebop` file in either your home
directory or the root of your project. If you use an extension of `.coffee` it
will be imported as a coffeescript module. Properties exported in this module
will be used to override the defaults used.

### Example `.bebop` configuration file

```coffeescript
fs        = require 'fs'
path      = require 'path'
requisite = require 'requisite'

module.exports =
  port: 3001

  compilers:
    jade: (src) ->
      # only compile index.jade file
      if /index.jade$/.test src
        "jade --pretty #{src} --out #{path.dirname src}"

    # use requisite to bundle client-side coffee script files
    coffee: (src, dst, cb) ->
      requisite.bundle {entry: src}, (err, bundle) ->
        return cb err if err?

        fs.writeFileSync dst, bundle.toString()
        cb null, true
```

### Editor integration
Integration with vim is provided by
[vim-bebop](http://github.com/zeekay/vim-bebop). You can do all sorts of fancy
stuff like evaluate Javascript, Coffeescript, get completions, etc.

### API
#### bebop.BebopClient
Client which connects back to `BebopClientServer`, generally a browser.

#### bebop.BebopClientServer
Websocket server which clients, generally browsers, connect to.

#### bebop.BebopControlServer
Websocket server which can be connected to by controlling clients, generally editors.

#### bebop.StaticServer
Static file server which injects bebop client-side js automtatically, with
optional support for basicAuth.

#### bebop.Compiler
File preprocessor used to compile from one language to another, compress files,
etc. Can be configured uniquely for each project, allowing different files to be
preprocessed as needed.

```javascript
Processor  = require('bebop').Processor
processors = require('bebop').processors

var processor = new Processor({
  coffee: {
    match: /\.coffee$/,
    process: [processors.coffee, processors.uglify]
  },
  jade: {
    match: /\.jade$/,
    process: function(src) {
      return 'jade --pretty ' + src;
    }
  },
  stylus: {
    match: /\.styl$/,
    process: function(src) {
      return 'stylus ' + src;
    }
  }
})
```

#### bebop.middleware
Connect/express middleware which also supports `http.Server` instances.
Injects and serves bebop client JavaScript automatically.
