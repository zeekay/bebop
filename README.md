## bebop [![Build Status](https://travis-ci.org/zeekay/bebop.svg?branch=master)](https://travis-ci.org/zeekay/bebop)
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
  port: 3000

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
