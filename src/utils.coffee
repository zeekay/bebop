path = require 'path'
log  = require './log'

exports.defaultExclude = /bebop.coffee$|bebop.js$/

exports.requireLocal = (modulePath) ->
  localPath = path.join process.cwd(), '/node_modules/', modulePath
  try
    return require localPath
  catch err
    try
      return require modulePath
    catch err
      log.error modulePath + ' not found, try npm install -g ' + modulePath
      process.exit 1
