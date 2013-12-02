module.exports =
  coffee: (src) ->
    "coffee -bmc #{src}"

  jade: (src) ->
    "jade --pretty #{src}"

  styl: (src) ->
    "stylus #{src}"
