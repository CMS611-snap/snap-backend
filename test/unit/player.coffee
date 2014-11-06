assert = require('chai').assert
Player = require('../../models/player')

describe 'Player', ->
  describe '#constructor', ->
    it 'generates an uuid for each player', ->
      player = new Player
      assert.equal(player.uuid.length == 36, true)
