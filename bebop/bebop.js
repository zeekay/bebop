(function(){
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
                try {
                    var obj = eval.call(window, data.msg),
                        prop,
                        properties = [];
                    for (prop in obj) {
                        properties.push(prop);
                    }
                    ws.send(JSON.stringify({'evt': 'complete', 'result': properties}));
                } catch (err) {
                    ws.send(JSON.stringify({'evt': 'complete', 'result': []}));
                }
                break;

            case 'eval':
                try {
                    var res = eval.call(window, data.msg);
                    ws.send(JSON.stringify({'evt': 'eval', 'result': res}));
                } catch (err) {
                    ws.send(JSON.stringify({'evt': 'eval', 'result': err.message}));
                }
                break;

            case 'fileModified':
                if (!window.bebopReloadHook) {
                    window.location.reload();
                } else {
                    bebopReloadHook(data.msg);
                }
                break;
        }
    };

    ws.onclose = function() {
        console.log('Connection to Reloader closed');
    };
}());
