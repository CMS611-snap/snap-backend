# vim: ts=2:sw=2:sta
io = require('socket.io-client')

url = process.env.TEST_TARGET || 'https://snap-backend-dev.herokuapp.com' #'http://localhost:8080'

users = process.env.USERS || 50

randWord = (len) ->
  Math.random().toString(36).substr(2, len)

startPlayer = (name) ->
  socket = io(url, {multiplex: false})

  socket.on 'connect', ()->
    setTimeout () ->
      socket.emit 'new player', name

      console.log "connected a test player #{name}"

      setInterval () ->
        w = randWord(2)
        socket.emit 'new word', w
        console.log "#{name} wrote: #{w}"
      , 1000
    , Math.random()*2000

for a in [0..users]
  startPlayer(process.env.TEST_NAME || "player #{a}")
  # console.log randWord(2)
