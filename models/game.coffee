class Game
  constructor: (@io) ->
     @players = []
     @maxScore = 10

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)

  addWord: (player, word) ->
    
    #Reject word if already guessed by player
    if player.hasGuessed(word)
      return

    snapped = false
    for p in @players
      if p.hasGuessed(word)
        snapped = true
        if p.hasSnapped(word)
          p.sendSnap(word, 1)
    
    if snapped
      player.sendSnap(word, 1)
    player.addWord(word)

  gameOver: () ->
    @io.emit "gameOver",
      winners:(p.name for p in @players when p.score == @maxScore)

module.exports = Game
