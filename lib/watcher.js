module.exports = function(dir, callback) {
  require('monocle')().watchDirectory({
    root: dir,
    directoryFilter: ['!node_modules', '!.git'],
    fileFilter: ['!package.json', '!.*', '!npm-debug.log', '!Cakefile', '!README.md'],
    listener: callback
  })
}
