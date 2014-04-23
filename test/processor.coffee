{processors, Processor} = require '../src'

processor = new Processor
  coffee: (src) ->
    "coffee -bcm #{src}"

  jade:
    match: /\.jade$/
    process: (src) ->
      "jade --pretty " + src

  stylus:
    match: /\.styl$/
    process: (src) ->
      "stylus " + src

describe 'processor', ->
  it 'should understand rules in array format', ->
    processor = new Processor [
        match:   /\.coffee$/
        process: processors.coffee
      ,
        match:   /\.jade$/
        process: (src) ->
          "jade --pretty " + src
      ,
        match: /\.styl$/
        process: (src) ->
          "stylus " + src
    ]
