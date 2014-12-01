UuidLib = require 'node-uuid'

WordStatus =
  guessed: 1
  snapped: 2

class Player
  constructor: (@id, @socket, @game,  @name = "") ->
    @words = {}
    @word_count = 0
    # @words = []
    # @snappedWords = []
    @score = 0
    @uuid = UuidLib.v4()
    @connected = true


  hasGuessed: (word) ->
    @words[word]?

  hasSnapped: (word) ->
    @words[word]? and @words[word] == WordStatus.snapped

  addWord: (word) ->
    return false if @hasGuessed(word)
    @words[word] = WordStatus.guessed
    @word_count += 1
    true

  sendSnap: (word, d_score, otherPlayer)->
    @score += d_score
    @words[word] = WordStatus.snapped
    console.log "#{@name}: #{@score}"
    @socket.emit "snap",
      player:otherPlayer
      d_score:d_score
      word:word

  reset: () ->
    @words = {}
    @word_count = 0
    @score = 0


module.exports = Player
