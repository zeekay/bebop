walk = (dir, callback) ->
  stream = require("readdirp")(
    root: dir
    directoryFilter: directoryFilter
    fileFilter: fileFilter
  )
  stream.on "data", (file) ->
    callback file.fullPath

watchFile = (filename, callback) ->
  watching[filename].close()  if watching[filename]
  watching[filename] = fs.watch(filename, ->
    callback filename
    watchFile filename, callback
  )
watch = (dir, callback) ->
  walk dir, (filename) ->
    watchFile filename, callback

fs = require("fs")
directoryFilter = ["!node_modules", "!.git"]
fileFilter = ["!package.json", "!.*", "!npm-debug.log", "!Cakefile", "!README.md"]
watching = {}

# Export watchFile and watch
watch.watchFile = watchFile
watch.walk = walk
module.exports = watch
