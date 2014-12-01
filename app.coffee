#!/usr/bin/env coffee
if process.env.NODETIME_ACCOUNT_KEY
  require('nodetime').profile
    accountKey: process.env.NODETIME_ACCOUNT_KEY
    appName: 'Snap backend'

express = require('express')
exphbs = require('express-handlebars')
app = express()
server = require('http').createServer(app)
io = require('socket.io')(server)
port = process.env.PORT || 8080
require("coffee-script/register")

app.engine('handlebars', exphbs({defaultLayout: 'main'}))
app.set('view engine', 'handlebars')

if process.env.NO_LOGS? and process.env.NO_LOGS
  console.log = () ->

server.listen port, ()->
  console.log('Server listening at port %d', port)

################################################
# Database stuff

DbHelper = require('./helpers/db_helper')

################################################
# Models
Player = require('./models/player')

Game = require('./models/game')
game = new Game io, DbHelper,
    maxScore: null,
    maxSeconds: null,
    maxWords: null

################################################
# RPC methods
app.get '/rpc/words', (req, res) ->
  res.send(game.getWords())

# Returns a list dictionary { word: count, ...}
app.get '/rpc/wordcounts', (req, res) ->
  res.send(game.getWordCounts())

app.get '/rpc/wordcloud', (req, res) ->
  res.send(wordCloudData())

wordCloudData = () ->
  multiplier = 10
  words = game.getWordCounts()
  wordCounts = []
  for countedWord in words
    wordCounts.push
      text: countedWord,
      size: words[countedWord] * multiplier,
      score: words[countedWord]
      #size: Math.sqrt(words[countedWord] * 200)
  return (
    words: wordCounts,
    multiplier: multiplier
  )

require('./pages/games.coffee')(app, DbHelper)

app.use('/', express.static(__dirname + '/public'))

################################################
# Socket.io
io.on 'connection', (socket) ->
  console.log("CONNECTION")

  socket.on 'start game', () ->
    game.startGame()

  socket.on 'stop game', () ->
    game.gameOver()
  
  socket.on 'set topic', (topic) ->
    game.setTopic(topic)

  socket.on 'new player', (playerName) ->
    console.log("PLAYER " + playerName)
    player = new Player(0, socket, game, playerName)

    DbHelper.addPlayer playerName, player.uuid

    socket.player = player

    game.addPlayer(player)

    socket.emit 'user joined',
      player: socket.player.name

    game.sendScores()

  # when the client emits 'new message', this listens and executes
  socket.on 'new word', (word) ->

    if !socket.player
      console.error("word " + word + " from unknown player")
      return

    game.addWord(socket.player, word)
   
    if (game.start)
      console.log("WORD " + word)
      socket.emit 'new word',
        player: socket.player.name,
        word: word

    # TODO(sam): this is a hack to get the moderator interface to work we
    # should have moderators join like any player and notify only moderator
    # sockets
    io.sockets.emit('wordcloud', wordCloudData())

  # when the user disconnects.. perform this
  socket.on 'disconnect', () ->
    # console.log "Closed."
    # console.log socket
    socket.player.connected = false

module.exports = app