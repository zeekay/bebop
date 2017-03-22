require 'shortcake'

use 'cake-bundle'
use 'cake-outdated'
use 'cake-publish'
use 'cake-version'

option '-g', '--grep [filter]', 'test filter'

task 'clean', 'clean project', (options) ->
  exec 'rm -rf dist/'

task 'build', 'build project', (options) ->
  Promise.all [
    bundle.write
      dest:   'src/bebop.min.js'
      entry:  'src/client/index.coffee'
      format: 'web'
      minify: true

    bundle.write
      entry:  'src/index.coffee'
      format: 'cjs'

    bundle.write
      entry:  'src/index.coffee'
      format: 'es'
  ]

task 'watch', 'watch for changes and recompile project', ->
  exec.parallel '''
    coffee -bcmw -o lib/ src/
    requisite src/client -m -w -o bebop.min.js
    '''

task 'test', 'Run tests', ['build'], (opts) ->
  bail     = opts.bail     ? true
  coverage = opts.coverage ? false
  grep     = opts.grep     ? ''
  test     = opts.test     ? 'test/'
  verbose  = opts.verbose  ? ''

  bail    = '--bail' if bail
  grep    = "--grep #{opts.grep}" if grep
  verbose = 'VERBOSE=true' if verbose

  if coverage
    bin = 'istanbul --print=none cover _mocha --'
  else
    bin = 'mocha'

  {status} = yield exec.interactive "NODE_ENV=test #{verbose}
        #{bin}
        --colors
        --reporter spec
        --timeout 10000000
        --compilers coffee:coffee-script/register
        --require co-mocha
        --require postmortem/register
        #{bail}
        #{grep}
        #{test}"

  process.exit status if opts.ci

task 'test:ci', 'Run tests', (opts) ->
  invoke 'test', bail: true, coverage: true, ci: true

task 'gh-pages', 'Publish docs to gh-pages', ->
  brief = require 'brief'
  brief.update()
