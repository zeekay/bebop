window.onload = function() {

    var bebop = {

        tags: {
            js: {
                link: 'src',
                name: 'script',
                type: 'text/script'
            },
            css: {
                link: 'href',
                name: 'link',
                type: 'text/css'
            }
        },

        randomizeUrl: function(url){
            return url + '?bebop=' + (((1+Math.random())*0x100000)|0).toString(16);
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
            var node,
                nodes,
                resource = this.urlParse(url);

            nodes = document.getElementsByTagName(resource.tag.name);

            for (var i=0; i<nodes.length; i++) {
                node = nodes[i];
                if (node[resource.tag.link].indexOf(resource.filename) !== -1){
                    node._resource = resource;
                    return node;
                }
            }
            return false;
        },

        reload: function(node) {
            var link = node._resource.tag.link;
            node.setAttribute(link, this.randomizeUrl(node[link]));
        },

        load: function(resource) {
            var node = document.createElement(resource.tag.name);
            node[resource.tag.link] = resource.url;
            node.type = resource.tag.type;
            document.getElementsByTagName('head')[0].appendChild(node);
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

        oneval: function(msg){
            try {
                var res = eval.call(root, msg);
                this.ws.send(JSON.stringify({'evt': 'eval', 'result': res}));
            } catch (err) {
                this.ws.send(JSON.stringify({'evt': 'eval', 'result': err.message}));
            }
        },

        onmodified: function(msg) {
            var node = this.findNode(msg);

            if (node)
                this.reload(node);
            else
                window.location.reload();
        },

        connectBrowser: function() {
            var WebSocket = window.WebSocket || window.MozWebSocket;
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
                        this.oncomplete(data.msg);
                        break;

                    case 'eval':
                        this.oneval(data.msg);
                        break;

                    case 'modified':
                        this.onreload(data.msg);
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
        root = global;
    } else {
        root = window;
        bebop.connectBrowser();
    }

    if (typeof root.bebop === 'undefined')
        root.bebop = bebop;

};
