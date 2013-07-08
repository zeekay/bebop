module.exports =
  coffee: (fn) ->
    "coffee -bc #{fn}"

  jade: (fn) ->
    "jade #{fn}"

  styl: (fn) ->
    "stylus #{fn}"
