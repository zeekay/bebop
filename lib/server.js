module.exports = {
  createServer: function() {
    var connect = require('connect');

    var app = connect();
    app.use(connect.logger('dev'));
    app.use(connect.static(process.cwd()));
    app.use(connect.directory(process.cwd(), {hidden: true}));

    var server = http.createServer(app),
        wss    = require('./websocket')(server);

    return this.server = server;
  },
  run: function() {
    server.listen(3000, '0.0.0.0', function() {
      console.log('bebop listening on 0.0.0.0:3000')
    })
  }
}
