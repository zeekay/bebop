(function() {
   var bebop = {

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

        randomizeUrl: function(url){
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

        reload: function(node) {
            if (node._resource.ext === 'js') {
                node.parentNode.removeChild(node);
                return this.load(node._resource);
            }
            var link = node._resource.tag.link;
            node[link] = this.randomizeUrl(node[link]);
            console.log('Reloaded ' + node[link]);
        },

        load: function(resource) {
            var node = document.createElement(resource.tag.name);
            node[resource.tag.link] = resource.url;
            node.type = resource.tag.type;
            document.getElementsByTagName('head')[0].appendChild(node);
            console.log('Loaded ' + node[resource.tag.link]);
        },

        oncomplete: function(msg) {
            try {
                var prop, properties = [];
                var obj = eval.call(root, msg);
                for (prop in obj)
                    properties.push(prop);
                this.ws.send(JSON.stringify({'evt': 'complete', 'result': properties}));
            } catch (err) {
                this.ws.send(JSON.stringify({'evt': 'complete', 'result': []}));
            }
        },

        oneval: function(msg) {
            try {
                var res = eval.call(root, msg);
                this.ws.send(JSON.stringify({'evt': 'eval', 'result': res}));
            } catch (err) {
                this.ws.send(JSON.stringify({'evt': 'eval', 'result': err.message}));
            }
        },

        onmodified: function(msg) {
            var node = this.findNode(msg);
            if (msg !== '' && node)
                this.reload(node);
            else
                location.reload();
        },

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
                }
            };

            ws.onclose = function() {
                console.log('Connection to Reloader closed');
            };

            this.ws = ws;
        },

        webSocketFallback: function() {
            // Unimplemented
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

}());
