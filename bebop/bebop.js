(function() {
   var bebop = {

        sync: false,

        reload: function(node) {
            if (node._resource.ext === 'js') {
                node.parentNode.removeChild(node);
                return this.load(node._resource);
            }
            var link = node._resource.tag.link;
            node[link] = this.urlRandomize(node[link]);
            console.log('Reloaded ' + node[link]);
        },

        load: function(resource) {
            var node = document.createElement(resource.tag.name);
            node[resource.tag.link] = resource.url;
            node.type = resource.tag.type;
            document.getElementsByTagName('head')[0].appendChild(node);
            console.log('Loaded ' + node[resource.tag.link]);
        },

        // Event handlers
        oncomplete: function(msg) {
            try {
                var obj = eval.call(root, msg);
                this.send({'evt': 'complete', 'result': this.dir(obj)});
            } catch (err) {
                this.send({'evt': 'complete', 'result': []});
            }
        },

        oneval: function(msg) {
            try {
                var res = eval.call(root, msg);
                this.send({'evt': 'eval', 'result': res});
            } catch (err) {
                this.send({'evt': 'eval', 'result': err});
            }
        },

        onmodified: function(msg) {
            var node = this.findNode(msg);
            if (msg !== '' && node)
                this.reload(node);
            else
                location.reload();
        },

        onsync: function(msg) {
            // Not implemented
        },

        dir: function(object) {
            var property, properties = [];

            function valid(name) {
                var invalid = ['arguments', 'caller', 'name', 'length', 'prototype'];
                for (var i in invalid) {
                    if (invalid[i] === name)
                        return false;
                }
                return true;
            }

            if (Object.getOwnPropertyNames !== 'undefined') {
                properties = Object.getOwnPropertyNames(object);
                properties = properties.filter(function(name) { return valid(name); });
                for (property in object) {
                    if (typeof property === 'string' && !(property in properties))
                        properties.push(property);
                }
            } else {
                for (property in object)
                    properties.push(property);
            }

            return properties;

        },

        dump: function(object) {
            var funcname,
                objects = [],
                paths = [],
                that = this;

            return (function derez(value, path) {
                var i,
                    name,
                    nu,
                    properties;

                switch (typeof value) {
                case 'object':
                    if (!value)
                        return null;

                    for (i = 0; i < objects.length; i += 1) {
                        if (objects[i] === value)
                            return {$ref: paths[i]};
                    }

                    objects.push(value);
                    paths.push(path);

                    if (Object.prototype.toString.apply(value) === '[object Array]') {
                        nu = [];
                        for (i = 0; i < value.length; i += 1)
                            nu[i] = derez(value[i], path + '[' + i + ']');
                    } else {
                        nu = {};
                        properties = that.dir(value);
                        for (i in properties) {
                            name = properties[i];

                            if (typeof value[name] === 'function') {
                                // Crop source
                                funcname = (value[name].toString().split(')')[0] + ')').replace(' ' + name, '');

                                // Don't recurse farther if function doesn't have valid properties
                                if (that.dir(value[name]).length < 1) {
                                    nu[name] = funcname;
                                } else {
                                    nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']');
                                }
                            } else {
                                nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']');
                            }
                        }
                    }
                    return nu;
                case 'number':
                case 'string':
                case 'boolean':
                    return value;
                case 'function':
                    try {
                        properties = that.dir(value);
                        objects.push(value);
                        paths.push(path);

                        nu = {};

                        for (i in properties) {
                            name = properties[i];

                            if (typeof value[name] === 'function') {
                                // Prettify name for JSON
                                funcname = (value[name].toString().split(')')[0] + ')').replace(' ' + name, '');

                                // Don't recurse farther if function doesn't have valid properties
                                if (that.dir(value[name]).length < 1) {
                                    nu[name] = funcname;
                                } else {
                                    nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']');
                                }
                            } else {
                                nu[name] = derez(value[name], path + '[' + JSON.stringify(name) + ']');
                            }
                        }

                        return nu;
                    } catch (err) {
                        return nu;
                        //
                    }
                }
            }(object, '$'));
        },

        // Websockets
        connect: function() {
            var that = this,
                WebSocket = root.WebSocket || root.MozWebSocket;

            if (!WebSocket) {
                return console.log('WebSockets not supported');
            }

            var ws = new WebSocket('ws://127.0.0.1:9000');

            ws.onopen = function() {
                console.log('Connected to Bebop');
            };

            ws.onmessage = function(evt) {
                var data = JSON.parse(evt.data);
                switch(data.evt) {
                    case 'complete':
                        that.oncomplete(data.msg);
                        break;
                    case 'eval':
                        that.oneval(data.msg);
                        break;
                    case 'modified':
                        that.onmodified(data.msg);
                        break;
                    case 'sync':
                        that.onsync(data.msg);
                        break;
                }
            };

            ws.onclose = function() {
                console.log('Connection to Reloader closed');
            };

            this.ws = ws;
        },

        send: function(msg) {
            this.ws.send(JSON.stringify(msg));
        },

        webSocketFallback: function() {
            // Not implemented
        },

        // DOM Manipulation
        tags: {
            js: {
                link: 'src',
                name: 'script',
                type: 'text/javascript'
            },
            css: {
                link: 'href',
                name: 'link',
                type: 'text/css'
            }
        },

        findNode: function(url) {
            if (url === '')
                return false;

            var node, nodes, resource;
            try {
                resource = this.urlParse(url);
                nodes = document.getElementsByTagName(resource.tag.name);

                for (var i=0; i<nodes.length; i++) {
                    node = nodes[i];
                    if (node[resource.tag.link].indexOf(resource.filename) !== -1){
                        node._resource = resource;
                        return node;
                    }
                }
            } catch (err) {
                return false;
            }
            return false;
        },

        // Urls
        urlRandomize: function(url){
            url = url.replace(/[?&]bebop=\w+/, '');
            url += (url.indexOf('?') === -1) ? '?' : '&';
            return url + 'bebop=' + (((1+Math.random())*0x100000)|0).toString(16);
        },

        urlParse: function(url) {
            var ext,
                filename,
                path,
                resource;

            // Determine path, filename and extension
            // Not terribly robust, might want to use *gasp* regex
            path = url.split('/');
            filename = path.pop();
            ext = filename.split('.')[1];

            resource = {
                ext: ext,
                filename: filename,
                path: path,
                tag: this.tags[ext],
                url: url
            };

            return resource;
        }

    };

    var root;

    if (typeof window === 'undefined') {
        // Node.js
        root = global;
        root.WebSocket = require('ws');
        module.exports = bebop;
    } else {
        // Browser
        root = window;
        bebop.connect();
    }

    if (typeof root.bebop === 'undefined')
        root.bebop = bebop;

    // Useful globals
    root.dir = bebop.dir;
    root.dump = bebop.dump;

}());

console.log(dump(Array));

