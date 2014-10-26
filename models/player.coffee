class Player
  constructor: (@id, @socket, @name = "") ->
  	@words = []
  	@score = 0


  canAddWord: (word) ->
  	@words.indexOf(word) == -1

  addWord: (word) ->
  	return false unless @canAddWord(word)
  	@words.push(word)
  	true

  sendSnap: (word, d_score)->
  	@score += d_score
  	console.log @score
  	@score
  	# send stuff



module.exports = Player
