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
        if not p.hasSnapped(word)
          p.sendSnap(word, 1)

    if snapped
      player.sendSnap(word, 1)

    player.addWord(word)

    if @isGameOver()
      @gameOver()

  isGameOver: () ->
    over = false
    for p in @players
      if p.score >= @maxScore
        over = true
    return over

  gameOver: () ->
    @io.emit "gameOver",
      winners:(p.name for p in @players when p.score == @maxScore)
    @exportData()

  exportData: () ->
    freq = {}
    for p in @players
      for word in p.words
        if word in freq
          freq[word] += 1
        else
          freq[word] = 1
    csv = ''
    for word, frequency of freq
      csv = csv + word + ', '+frequency + '\n'
    #TODO: do something with csv
    console.log(csv)

  getWordCounts: () ->
    counts = {}
    for player in @players
      for word in player.words
        if word of counts
          counts[word] += 1
        else
          counts[word] = 1
    return counts

module.exports = Game
