import Bebop      from './bebop'
import compilers  from './compilers'
import middleware from './middleware'
import server     from './server'
import websocket  from './websocket'

bebop = new Bebop

bebop.Bebop      = Bebop
bebop.compilers  = compilers
bebop.middleware = middleware
bebop.server     = server
bebop.websocket  = websocket

export default bebop
