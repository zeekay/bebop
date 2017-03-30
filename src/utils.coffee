import os   from 'os'
import path from 'path'

import log  from './log'

export defaultExclude = /bebop.coffee$|bebop.js$/

# Locally require a module
export requireLocal = (modulePath) ->
  localPath = path.join process.cwd(), '/node_modules/', modulePath
  try
    return require localPath
  catch err
    try
      return require modulePath
    catch err
      log.error modulePath + ' not found, try npm install -g ' + modulePath
      process.exit 1

# Return the first IPv4 address
exports firstAddress = ->
  for _, iface of os.networkInterfaces()
    for addr in iface
      # Skip IPv6 addresses
      unless addr.family is 'IPv4'
        continue

      # Skip private addresses
      if addr.internal
        continue

      return addr.address
