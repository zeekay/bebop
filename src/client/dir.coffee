# introspection
export default (object) ->
  valid = (name) ->
    invalid = ['arguments', 'caller', 'name', 'length', 'prototype']
    for i of invalid
      return false  if invalid[i] is name
    true
  properties = []
  seen = {}
  if Object.getOwnPropertyNames isnt 'undefined'
    properties = Object.getOwnPropertyNames(object)
    for property of object
      properties.push property
    properties = properties.filter((name) ->
      valid name
    )
    i = 0

    while i < properties.length
      seen[properties[i]] = ''
      i++
    return Object.keys(seen)
  else
    for property of object
      properties.push property
  properties
