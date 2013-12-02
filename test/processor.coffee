{processors, Processor} = require 'bebop'

processor = new Processor [
    match: /\.coffee$/
    process: [processors.coffee, processors.uglify]
  ,
    match: /\.jade$/
    process: (src) ->
      "jade --pretty " + src
  ,
    match: /\.styl$/
    process: (src) ->
      "stylus " + src
]

processor = new Processor
  coffee: (src) ->
    "coffee -bcm #{src}"

    match: /\.jade$/
    process: (src) ->
      "jade --pretty " + src
  ,
    match: /\.styl$/
    process: (src) ->
      "stylus " + src
