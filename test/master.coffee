Master  = require '../lib/master'
request = require 'request'

describe 'Master', ->
  describe '#run', ->
    it 'should run server module', (done) ->
      master = new Master __dirname + '/assets/server', port: 3333
      master.run()
      request 'http://localhost:3333', (err, res, body) ->
        body.should.eq 'hi'
        done()
