assert = require('assert')
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
      players.push newPlayer
      p_cb()
      
  # start the chain
  start = addPlayer.bind this, ()-> 
    cb players
  fn = addPlayer.bind this, start

  # chain the function n-2 times
  for i in [0...num-2]
    fn = addPlayer.bind this, fn

  fn()


describe "Snap", ->
  before (done) ->
    server.start port, done
  after (done) ->
    server.stop done

  it "should let players connect", (done) ->
    connectTestPlayers 10, (players)->
      assert.equal(players.length, 10)
      done()