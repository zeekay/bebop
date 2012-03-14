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
        var prop,
            data = JSON.parse(evt.data);

        switch(data.evt) {
            case 'complete':
                properties = [];
                var obj = eval.call(window, data.msg);
                for (prop in obj) {
                    if (obj.hasOwnProperty(prop)) {
                        properties.push(prop);
                    }
                }
                ws.send(JSON.stringify({'evt': 'completion', 'completions': properties}));
                break;
            case 'eval':
                try {
                    var res = eval.call(window, data.msg);
                    console.log(res);
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
