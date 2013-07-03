if not fs.watch
  throw new Error 'Watching for changes requires fs.watch'

# watch files in current directory
require('bebop/lib/watch').walk process.cwd(), (filename) =>
  @watch filename, =>
    @livereload filename

# watch modules being required in
require('./watch') (filename) =>
  @watch filename, =>
    @livereload filename, true
    @reload()
  , true

# Watch files for changes
watch: (filename, callback, force = false) ->
  # Ensure that force watched modules replace existing callbacks, but can't be replaced themselves
  if (cached = @watched[filename])? and cached.force and not force
    return

  # @logger.log 'debug', "watching #{filename}", force: force

  @watched[filename].close() if @watched[filename]

  try
    @watched[filename] = fs.watch filename, =>
      setTimeout =>
        @watch filename, callback, force
      , 50
      callback()
    @watched[filename].force = force

  catch err
    if err.code == 'EMFILE'
      @logger.log 'Too many open files, try to increase the number of open files'
      process.exit 1
    else
      throw err
