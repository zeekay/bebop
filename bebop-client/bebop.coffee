do ->
  isBrowser = if typeof window is 'undefined' then false else true
  root = if isBrowser then window else global

  unless isBrowser
    root.location =
      protocol: 'http:'
      hostname: 'localhost'
      port:     '3333'

  class Bebop
    constructor: (opts) ->
      protocol = opts.protocol ? if location.protocol is 'http:' then 'ws://' else 'wss://'
      hostname = opts.hostname ? location.hostname
      port     = opts.port     ? location.port
      @address = opts.address  ? protocol + hostname + ':' + port + '/_bebop'
      @tries   = 0

    # Called when completion requested.
    oncomplete: (msg) ->
      try
        obj = eval_.call(root, msg)
        @send
          type: 'complete'
          result: @dir(obj)

      catch e
        @send
          type: 'complete'
          result: []

    # Called when eval requested.
    oneval: (msg) ->
      try
        res = eval_.call(root, msg)
        @send
          type: 'eval'
          result: res

      catch e
        error =
          error: e.message
          stack: @stacktrace(e)

        @send
          type: 'eval'
          result: error

    onmodified: (filename) ->
      if isBrowser
        node = @findNode filename
        if node and node._resource.tag.name != 'script'
          @reload node
        else
          location.reload true

    onopen: ->
      @tries = 0
      @log 'connected'

    onclose: ->
      @log 'closed'

    # close websocket connection
    close: ->
      @ws.onclose = ->
      @ws.close()

    # reloading
    reload: (node) ->
      if node._resource.ext is 'js'
        node.parentNode.removeChild node
        return @load(node._resource)

      link = node._resource.tag.link
      node[link] = @urlRandomize(node._resource.url)
      @log 'resource-reloaded', node[link]

    load: (resource) ->
      node = document.createElement(resource.tag.name)
      node[resource.tag.link] = resource.url
      node.type = resource.tag.type
      document.getElementsByTagName('head')[0].appendChild node
      @log 'resource-loaded', node[resource.tag.link]

    # introspection
    dir: (object) ->
      valid = (name) ->
        invalid = ['arguments', 'caller', 'name', 'length', 'prototype']
        for i of invalid
          return false  if invalid[i] is name
        true
      properties = []
      seen = {}
      if Object.getOwnPropertyNames isnt 'undefined'
        properties = Object.getOwnPropertyNames(object)
        for property of object
          properties.push property
        properties = properties.filter((name) ->
          valid name
        )
        i = 0

        while i < properties.length
          seen[properties[i]] = ''
          i++
        return Object.keys(seen)
      else
        for property of object
          properties.push property
      properties

    # inspired by https://github.com/douglascrockford/JSON-js/blob/master/cycle.js
    dump: (object) ->
      objects = []
      paths = []

      (derez = (value, path) =>
        switch typeof value
          when 'object'
            return null  unless value
            i = 0
            while i < objects.length
              return $ref: paths[i]  if objects[i] is value
              i += 1
            objects.push value
            paths.push path
            if Object::toString.apply(value) is '[object Array]'
              nu = []
              i = 0
              while i < value.length
                nu[i] = derez(value[i], path + '[' + i + ']')
                i += 1
            else
              nu = {}
              properties = @dir(value)
              for i of properties
                name = properties[i]
                if typeof value[name] is 'function'

                  # Crop source
                  funcname = (value[name].toString().split(')')[0] + ')').replace(' ' + name, '')

                  # Don't recurse farther if function doesn't have valid properties
                  if @dir(value[name]).length < 1
                    nu[name] = funcname
                  else
                    try
                      nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
                else
                  try
                    nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
            nu

          when 'number', 'string', 'boolean'
            value

          when 'function'
            try
              properties = @dir(value)
              objects.push value
              paths.push path
              nu = {}
              for i of properties
                name = properties[i]
                if typeof value[name] is 'function'

                  # Prettify name for JSON
                  funcname = (value[name].toString().split(')')[0] + ')').replace(' ' + name, '')

                  # Don't recurse farther if function doesn't have valid properties
                  if @dir(value[name]).length < 1
                    nu[name] = funcname
                  else
                    nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
                else
                  nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']')
              return nu
            catch e
              return nu
      ) object, '$'

    log: (event, message) ->
      return unless root.console?

      if message
        console.log "bebop:#{event}", message
      else
        console.log "bebop:#{event}"

    # WebSockets
    connect: ->
      unless @tries < 10
        @log 'connection-failed', 'giving up!'
        return

      @tries++

      WebSocket = root.WebSocket or root.MozWebSocket

      unless WebSocket?
        if isBrowser
          @webSocketFallback()
        else
          WebSocket = require 'ws'

      try
        @ws = new WebSocket @address
      catch err
        root.setTimeout =>
          @connect
        , 500
        return

      if isBrowser
        root.onbeforeunload = =>
          @ws.close()

      @ws.onopen = =>
        @onopen()

        if isBrowser
          identifier = location.href + ' - ' + navigator.userAgent
        else
          identifier = process.argv[1] + ' - node'

        @send
          type: 'connected'
          identifier: identifier

      @ws.onclose = =>
        return
        setTimeout =>
          @connect()
        , 500

      @ws.onerror = =>
        setTimeout =>
          @connect()
        , 500

      @ws.onmessage = (message) =>
        message = JSON.parse message.data

        switch message.type
          when 'complete'
            @oncomplete message.name

          when 'eval'
            @oneval message.code

          when 'modified'
            @onmodified message.filename

          when 'reload'
            setTimeout =>
              @close()

              location.reload true
            , 2000

    send: (msg) ->
      @ws.send JSON.stringify msg

    webSocketFallback: ->
      root.WEB_SOCKET_SWF_LOCATION = 'https://github.com/gimite/web-socket-js/blob/master/WebSocketMain.swf?raw=true'
      urls = ['https://github.com/gimite/web-socket-js/blob/master/swfobject.js?raw=true',
              'https://github.com/gimite/web-socket-js/blob/master/web_socket.js?raw=true']
      @load @urlParse(urls[0])
      @load @urlParse(urls[1])

    # DOM Manipulation
    tags:
      js:
        link: 'src'
        name: 'script'
        type: 'text/javascript'

      css:
        link: 'href'
        name: 'link'
        type: 'text/css'

    parseFilename: (filename) ->
      # Determine path, filename and extension
      # Not terribly robust, might want to use *gasp* regex
      path = filename.split '/'
      filename = path.pop()
      ext = filename.split('.')[1]

      resource =
        ext: ext
        filename: filename
        path: path
        tag: @tags[ext]

      resource

    findNode: (filename) ->
      return if filename is ''
      return unless (resource = @parseFilename filename).tag?

      re = new RegExp filename + '$'

      for node in document.getElementsByTagName resource.tag.name
        if re.test (node[resource.tag.link].split '?')[0]
          resource.url = node[resource.tag.link]
          node._resource = resource
          return node

      null

    # Urls
    urlRandomize: (url) ->
      url = url.replace(/[?&]bebop=\w+/, '')
      url += (if (url.indexOf('?') is -1) then '?' else '&')
      url + 'bebop=' + (((1 + Math.random()) * 0x100000) | 0).toString(16)

    exportGlobals: ->
      # export a few useful globals
      globals =
        bebop: @

        dir: (obj) =>
          @dir obj

        dump: (obj) =>
          @dump obj

      for key of globals
        if typeof root[key] isnt 'undefined'

          # preserve existing global
          original = root[key]
          root[key] = globals[key]
          root[key]._original = original
        else
          root[key] = globals[key]

    # Stacktrace, borrowed from https://github.com/eriwen/javascript-stacktrace
    stacktrace: (e) ->
      method =
        chrome: (e) ->
          stack = (e.stack + '\n').replace(/^\S[^\(]+?[\n$]/g, '').replace(/^\s+(at eval )?at\s+/g, '').replace(/^([^\(]+?)([\n$])/g, '{anonymous}()@$1$2').replace(/^Object.<anonymous>\s*\(([^\)]+)\)/g, '{anonymous}()@$1').split('\n')
          stack.pop()
          stack

        firefox: (e) ->
          e.stack.replace(/(?:\n@:0)?\s+$/m, '').replace(/^\(/g, '{anonymous}(').split '\n'

        other: (curr) ->
          ANON = '{anonymous}'
          fnRE = /function\s*([\w\-$]+)?\s*\(/i
          stack = []
          fn = undefined
          args = undefined
          maxStackSize = 10
          while curr and curr['arguments'] and stack.length < maxStackSize
            fn = (if fnRE.test(curr.toString()) then RegExp.$1 or ANON else ANON)
            args = Array::slice.call(curr['arguments'] or [])
            stack[stack.length] = fn + '(' + @stringifyArguments(args) + ')'
            curr = curr.caller
          stack

        stringifyArguments: (args) ->
          result = []
          slice = Array::slice
          i = 0

          while i < args.length
            arg = args[i]
            if arg is undefined
              result[i] = 'undefined'
            else if arg is null
              result[i] = 'null'
            else if arg.constructor
              if arg.constructor is Array
                if arg.length < 3
                  result[i] = '[' + @stringifyArguments(arg) + ']'
                else
                  result[i] = '[' + @stringifyArguments(slice.call(arg, 0, 1)) + '...' + @stringifyArguments(slice.call(arg, -1)) + ']'
              else if arg.constructor is Object
                result[i] = '#object'
              else if arg.constructor is Function
                result[i] = '#function'
              else if arg.constructor is String
                result[i] = '"' + arg + '"'
              else result[i] = arg  if arg.constructor is Number
            ++i
          result.join ','

      if e['arguments'] and e.stack
        return method.chrome(e)
      else return method.firefox(e)  if e.stack
      method.other e

  if isBrowser
    root.Bebop = Bebop
  else
    module.exports = Bebop

    exports.start = (opts = {}) ->
      bebop = new Bebop opts

      if opts.useRepl
        repl = require 'repl'
        util = require 'util'

        # colorful output
        repl.writer = (obj, showHidden, depth) ->
          util.inspect obj, showHidden, depth, true

        bebop.onopen = ->
          repl.start 'bebop> ', null, null, true

      bebop.connect()
