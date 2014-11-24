io = require('socket.io-client')

url = process.env.TEST_TARGET || 'https://snap-backend-dev.herokuapp.com'


randWord = (len) ->
  Math.random().toString(36).substr(2, len)



startPlayer = () ->
  name = process.env.TEST_NAME || 'John Smith'

  socket = io(url)


  socket.on 'connect', ()->
    setTimeout () ->
      socket.emit 'new player', name

      console.log "connected a test player #{name}"

      setInterval () ->
        socket.emit 'new word', randWord(2)
      ,1000 + Math.random()*500
    ,Math.random()*2000

for a in [0..70]
  startPlayer()
  # console.log randWord(2)
