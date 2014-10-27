class Game
  constructor: () ->
     @players = []

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)

  addWord: (player, word) ->
    
    //Reject word if already guessed by player
    if word in player.words
      return

    snapped = false
    for p in @players
      if word in p.words
        p.sendSnap(word, 1)
        snapped = true
    
    if snapped
      player.sendSnap(word, 1)
    player.addWord(word)

module.exports = Game
