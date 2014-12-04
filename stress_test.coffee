# vim: ts=2:sw=2:sta
io = require('socket.io-client')

url = process.env.TEST_TARGET || 'https://snap-backend-dev.herokuapp.com' #'http://localhost:8080'

users = process.env.USERS || 50

WORD_CHARS = "abcdefghijklmnopqrstuvwxyz"

randWord = (len) ->
  word = ""
  for c in [1..len]
    index = Math.floor(Math.random() * WORD_CHARS.length)
    word += WORD_CHARS.charAt(index)
  return word

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
    , Math.random()*users*100

for a in [1..users]
  startPlayer(process.env.TEST_NAME || "player #{a}")
  # console.log randWord(2)
