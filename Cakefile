require 'shortcake'

use 'cake-version'
use 'cake-publish'

option '-g', '--grep [filter]', 'test filter'
option '-v', '--version [<newversion> | major | minor | patch | build]', 'new version'

task 'clean', 'clean project', (options) ->
  exec 'rm -rf lib'

task 'build', 'build project', (options) ->
  exec.parallel '''
  coffee -bcm -o lib/ src/
  requisite src/client -g -o bebop.js
  '''

task 'build-min', 'build project', (options) ->
  exec.parallel '''
  coffee -bc -o lib/ src/
  requisite src/client -m -o bebop.js
  '''

task 'watch', 'watch for changes and recompile project', ->
  exec.parallel '''
  coffee -bcmw -o lib/ src/
  requisite src/client -g -w -o bebop.js
  '''

task 'test', 'run tests', (options) ->
  grep = if opts.grep then "--grep #{opts.grep}" else ''
  test = opts.test ? 'test/'

  exec "NODE_ENV=test mocha
                      --colors
                      --reporter spec
                      --timeout 5000
                      --compilers coffee:coffee-script/register
                      --require postmortem/register
                      --require co-mocha
                      #{grep}
                      #{test}"

task 'gh-pages', 'Publish docs to gh-pages', ->
  brief = require 'brief'
  brief.update()
