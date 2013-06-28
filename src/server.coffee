module.exports = createServer: ->
  connect = require("connect")
  passport = require("passport")
  BasicStrategy = require("passport-http").BasicStrategy
  passport.use new BasicStrategy({}, (username, password, done) ->
    unless password is "beepboop"
      done null, false
    else
      done null, {}
  )
  app = connect()
  app.use connect.logger("dev")
  app.use passport.initialize()
  app.use passport.authenticate("basic",
    session: false
  )
  app.use connect.static(process.cwd())
  app.use connect.directory(process.cwd(),
    hidden: true
  )
  server = require("http").createServer(app)
  server.run = ->
    server.listen 3000, "0.0.0.0", ->
      console.log "bebop listening on 0.0.0.0:3000"


  server
