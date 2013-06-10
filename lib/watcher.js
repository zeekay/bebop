var directoryFilter = ['!node_modules', '!.git'],
    fileFilter = ['!package.json', '!.*', '!npm-debug.log', '!Cakefile', '!README.md'];

var watch =function(dir, callback) {
  require('monocle')().watchDirectory({
    root: dir,
    directoryFilter: directoryFilter,
    fileFilter: fileFilter,
    listener: callback
  })
}

watch.walk = function(dir, callback) {
  require('monocle/node_modules/readdirp')({
    root: dir,
    directoryFilter: directoryFilter,
    fileFilter: fileFilter
  },
  function(err, res) {
    res.files.map(function(file) {
      return file.fullPath
    }).forEach(callback)
  })
}

module.exports = watch;
