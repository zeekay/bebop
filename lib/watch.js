var fs = require('fs');

var directoryFilter = ['!node_modules', '!.git'],
    fileFilter = ['!package.json', '!.*', '!npm-debug.log', '!Cakefile', '!README.md'],
    watching = {};

function walk(dir, callback) {
  var stream = require('readdirp')({
    root: dir,
    directoryFilter: directoryFilter,
    fileFilter: fileFilter
  })

  stream.on('data', function (file) {
    callback(file.fullPath)
  });
}

function watchFile(filename, callback) {
  if (watching[filename]) {
    watching[filename].close()
  }

  watching[filename] = fs.watch(filename, function() {
    callback(filename)
    watchFile(filename, callback)
  })
}

function watch(dir, callback) {
  walk(dir, function(filename) {
    watchFile(filename, callback)
  })
}

// Export watchFile and watch
watch.watchFile = watchFile
watch.walk      = walk

module.exports = watch
