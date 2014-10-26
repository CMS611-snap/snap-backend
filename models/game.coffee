class Game
   constructor: () ->
     @players = []

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)

  addWord: (player, word) ->
    player.addWord(word)
    snapped = false
    for p in @players
      if word in p.words
        p.sendSnap(word, 1)
        snapped = true
    if snap
      player.sendSnap(word, 1)

module.exports = Game
