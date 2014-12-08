#!/usr/bin/env coffee
# vim: ts=2:sw=2

if process.env.NODETIME_ACCOUNT_KEY
  require('nodetime').profile
    accountKey: process.env.NODETIME_ACCOUNT_KEY
    appName: 'Snap backend'

express = require('express')
exphbs = require('express-handlebars')
bodyParser = require('body-parser')
app = express()

server = require('http').createServer(app)
io = require('socket.io')(server)
port = process.env.PORT || 8080
require("coffee-script/register")

app.engine('handlebars', exphbs({defaultLayout: 'main'}))
app.set('view engine', 'handlebars')
app.use bodyParser.json()
app.use bodyParser.urlencoded
    extended: true

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
game = new Game io, DbHelper

################################################
# RPC methods
app.get '/rpc/words', (req, res) ->
  res.send(game.getWords())

# Returns a list dictionary { word: count, ...}
app.get '/rpc/wordcounts', (req, res) ->
  res.send(game.getWordCounts())

app.get '/rpc/wordcloud', (req, res) ->
  res.send(wordCloudData())

app.get '/rpc/setup/endConfig', (req, res) ->
  res.send(game.endConfig)

app.post '/rpc/setup/endConfig', (req, res) ->
  game.setEndConfig req.body
  res.send()

app.get '/rpc/setup/metadata', (req, res) ->
  res.send
    metadata: game.metadata
    topic: game.topic

app.post '/rpc/setup/metadata', (req, res) ->
  game.metadata = req.body
  res.send()

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
    if socket?.player?
      return
    player = new Player(0, socket, game, playerName)
    socket.player = player
    DbHelper.addPlayer playerName, player.uuid
    game.addPlayer(player)

    console.log "PLAYER #{player.name} #{player.uuid}"
    player.socket.emit 'user joined', player.identifier()

  # when the client emits 'new message', this listens and executes
  socket.on 'new word', (word, cb) ->
    if !socket.player
      console.error("word " + word + " from unknown player")
      cb
        success: false
        error: "unknown player"
        snap: null
      return

    error = game.addWord socket.player, word, (error, snap) ->
      if !error?
        console.log("WORD #{word} from #{socket.player.name}")
      cb
        success: !error?
        error: error
        snap: snap

  # when the user disconnects.. perform this
  socket.on 'disconnect', () ->
    player = socket?.player
    return if not player?
    console.log "player #{player.name} #{player.uuid} disconnected"
    player.connected = false

module.exports = app
