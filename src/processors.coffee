module.exports =
  coffee: (src) ->
    "coffee -bmc #{src}"

  jade: (src) ->
    "jade --pretty #{src}"

  styl: (src) ->
    "stylus #{src}"

  uglify: (src) ->
    "uglifyjs #{src} -o #{src.replace /\.js$/, '.js.min'}"
