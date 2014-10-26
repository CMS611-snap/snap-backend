class Game
  constructor: () ->
     @players = []

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)

  addWord: (player, word) ->
    snapped = false
    for p in @players
      if word in p.words
        p.sendSnap(word, 1)
        snapped = true
    if snapped
      player.sendSnap(word, 1)
    player.addWord(word)

module.exports = Game
