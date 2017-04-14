use 'sake-bundle'
use 'sake-outdated'
use 'sake-publish'
use 'sake-test'
use 'sake-version'

task 'clean', 'clean project', (options) ->
  exec 'rm -rf lib/'

task 'build', 'build project', (options) ->
  b = new Bundle
    compilers:
      coffee: version: 1

  yield b.write
    entry:   'src/index.coffee'
    formats: ['cjs', 'es']

  yield b.write
    entry:  'src/cli.coffee'
    format: 'cli'
    executable: true

  yield b.write
    entry:     'src/client/index.coffee'
    dest:      'bebop.min.js'
    format:    'web'
    browser:   true
    minify:    false
    sourceMap: false

task 'watch', 'watch for changes and recompile project', ->

task 'gh-pages', 'Publish docs to gh-pages', ->
  brief = require 'brief'
  brief.update()
