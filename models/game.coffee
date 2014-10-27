class Game
  constructor: (@io) ->
     @players = []
     @maxScore = 10

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)

  addWord: (player, word) ->
    
    #Reject word if already guessed by player
    if word in player.words
      return

    snapped = false
    for p in @players
      if word in p.words
        snapped = true
        if word not in p.snappedWords
          p.sendSnap(word, 1)
    
    if snapped
      player.sendSnap(word, 1)
    player.addWord(word)

  gameOver: () ->
    @io.emit "gameOver",
      winners:(p.name for p in @players when p.score == @maxScore)

module.exports = Game
