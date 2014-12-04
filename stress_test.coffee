io = require('socket.io-client')

url = process.env.TEST_TARGET || 'https://snap-backend-dev.herokuapp.com' #'http://localhost:8080'

users = process.env.USERS || 50

randWord = (len) ->
  Math.random().toString(36).substr(2, len)



startPlayer = (name) ->
  name = name || process.env.TEST_NAME || 'John Smith'

  socket = io(url)


  socket.on 'connect', ()->
    setTimeout () ->
      socket.emit 'new player', name

      console.log "connected a test player #{name}"

      setInterval () ->
        w = randWord(2)
        socket.emit 'new word', w
        console.log "#{name} wrote: #{w}"
      ,10000000000 + Math.random()*500
    ,Math.random()*2000

for a in [0..users]
  startPlayer("player #{a}")
  # console.log randWord(2)
