import fs from 'fs'

import {requireLocal} from '../utils'

export default (src, dst, cb = ->) ->
  pug = requireLocal 'pug'

  html = pug.renderFile src,
    pretty: true

  fs.writeFile dst, html, (err) ->
    throw err if err?

    cb null, true
