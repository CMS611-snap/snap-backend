exec = require('child_process').exec
server = null
module.exports = 
	start: (port, cb)->
    server = exec("PORT=#{port} node app.js")
    server.stderr.on 'data', (data)->
      console.log data
    server.on 'close', ()->
      console.log 'The server has exited prematurely'
    # setTimeout (()->cb()), 1000
    cb()

  stop: (cb)->
    server.kill()
    cb()
