assert = require('chai').assert
io = require('socket.io-client')
server = require('./serverWrapper')
port = 5000+( Math.random()*100 | 0 )
options = 
  multiplex: false
socketURL = "http://0.0.0.0:#{port}"

connectTestPlayers = (num, cb)->
  players = []

  addPlayer = (p_cb)->
    newPlayer = io(socketURL, options)

    newPlayer.on "connect", ()->
      # assign a player a random name
      randInt = Math.random() * 100 | 0
      name = "player #{randInt}"
      newPlayer.emit 'new player', name
      newPlayer.game = {}
      newPlayer.game.name = name

      players.push newPlayer
      p_cb()

  # the players are added synchronously
  # start the chain
  start = addPlayer.bind this, ()-> 
    cb players

  if num == 1
    start()
    return

  fn = addPlayer.bind this, start

  # chain the function n-2 times
  for i in [0...num-2]
    fn = addPlayer.bind this, fn

  fn()

markAndCheck = (received, i, cb)->
  ()->
    received[i] = true
    if received.reduce(((prev, cur)-> prev && cur), true)
      cb()


describe "Snap", ->
  before (done) ->
    server.start port, done
  after (done) ->
    server.stop done

  it "should let players connect", (done) ->
    connectTestPlayers 10, (players)->
      assert.equal(players.length, 10)
      done()

  it "the user should receive 'user joined' after connection", (done) ->
    connectTestPlayers 1, (players)->
      players[0].on 'user joined', (data)->
        assert.equal data.player, players[0].game.name
        done()

  it "players should receive snap events", (done) ->
    connectTestPlayers 2, (players)->
      received = [false, false]
      for i in [0...players.length]
        players[i].on 'snap', markAndCheck(received, i, done)

      players[0].emit 'new word', 'foobar'
      players[1].emit 'new word', 'foobar'


