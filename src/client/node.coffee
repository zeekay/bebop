import tags  from './tags'
import log from './log'
import {urlRandomize} from './utils'

parseFilename = (filename) ->
  # Determine path, filename and extension
  # Not terribly robust, might want to use *gasp* regex
  path = filename.split '/'
  filename = path.pop()
  ext = filename.split('.')[1]

  resource =
    ext: ext
    filename: filename
    path: path
    tag: tags[ext]

  resource

export findNode = (filename) ->
  return if filename is ''
  return unless (resource = parseFilename filename).tag?

  re = new RegExp filename + '$'

  for node in document.getElementsByTagName resource.tag.name
    if re.test (node[resource.tag.link].split '?')[0]
      resource.url = node[resource.tag.link]
      node._resource = resource
      return node

  null

# reloading
export reloadNode = (node) ->
  if node._resource.ext is 'js'
    node.parentNode.removeChild node
    return load(node._resource)

  link = node._resource.tag.link

  # hack to get chrome to reload css
  if navigator.userAgent.toLowerCase().indexOf('chrome') > -1
    node[link] = '#break-the-url'

  # update url of resource
  node[link] = urlRandomize node._resource.url
  log.info 'resource-reloaded', node[link]

export load = (resource) ->
  node = document.createElement(resource.tag.name)
  node[resource.tag.link] = resource.url
  node.type = resource.tag.type
  document.getElementsByTagName('head')[0].appendChild node
  log.info 'resource-loaded', node[resource.tag.link]
