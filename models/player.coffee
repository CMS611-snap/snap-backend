UuidLib = require 'node-uuid'

class Player
  constructor: (@id, @socket, @game,  @name = "") ->
    @words = []
    @snappedWords = []
    @score = 0
    @uuid = UuidLib.v4()


  hasGuessed: (word) ->
    word in @words

  hasSnapped: (word) ->
    word in @snappedWords

  addWord: (word) ->
    return false if @hasGuessed(word)
    @words.push(word)
    true

  sendSnap: (word, d_score)->
    @score += d_score
    @snappedWords.push(word)
    console.log @name, @score
    @socket.emit "snap",
      player:@name
      d_score:d_score
      word:word


module.exports = Player
