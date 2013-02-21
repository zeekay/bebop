var properties = {},
    wrapper = {};

['client', 'server'].forEach(function(property) {
  properties[property] = {
    enumerable: true,
    get: function() {
      return require('./' + property);
    }
  }
});

Object.defineProperties(wrapper, properties);

module.exports = wrapper;
