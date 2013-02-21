var connect = require('connect');

module.exports = {
  run: function() {
    connect.createServer(connect.static(process.cwd())).listen(1337);
  }
}
