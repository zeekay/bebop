xian    = require '../lib'
request = require 'request'

describe 'xian', ->
  describe '#run', ->
    it 'should run server module', (done) ->
      xian.run __dirname + '/assets/server', port: 3333, logger: false, ->
        request 'http://localhost:3333', (err, res, body) ->
          body.should.eq 'hi'
          done()

    it 'should fail to run server module with error', (done) ->
      xian.run __dirname + '/assets/server-error', port: 3333, logger: false, ->
        request 'http://localhost:3333', (err, res, body) ->
          body.should.eq 'hi'
          done()
