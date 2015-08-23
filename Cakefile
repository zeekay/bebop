exec = require('executive').interactive

option '-g', '--grep [filter]', 'test filter'
option '-v', '--version [<newversion> | major | minor | patch | build]', 'new version'

task 'clean', 'clean project', (options) ->
  exec 'rm -rf lib'
  exec 'rm -rf .test'

task 'build', 'build project', (options) ->
  exec 'node_modules/.bin/coffee -bcm -o lib/ src/'
  exec 'node_modules/.bin/coffee -bcm -o .test/ test/'
  exec 'node_modules/.bin/coffee -cm bebop-client/'

task 'build-min', 'build project', (options) ->
  exec 'node_modules/.bin/coffee -bc -o lib/ src/'
  exec 'node_modules/.bin/coffee -c bebop-client/'

task 'watch', 'watch for changes and recompile project', ->
  exec 'node_modules/.bin/coffee -bcmw -o lib/ src/'
  exec 'node_modules/.bin/coffee -bcmw -o .test test/'
  exec 'node_modules/.bin/coffee -cmw bebop-client/'

task 'test', 'run tests', (options) ->
  test = options.test ? '.test'
  if options.grep?
    grep = "--grep #{options.grep}"
  else
    grep = ''

  exec "NODE_ENV=test ./node_modules/.bin/mocha
      --colors
      --reporter spec
      --timeout 5000
      --compilers coffee:coffee-script/register
      --require postmortem/register
      #{grep}
      #{test}"

task 'gh-pages', 'Publish docs to gh-pages', ->
  brief = require 'brief'
  brief.update()

task 'publish', 'publish project', (options) ->
  newVersion = options.version ? 'patch'

  exec """
  git push
  npm version #{newVersion}
  npm publish
  """.split '\n'
