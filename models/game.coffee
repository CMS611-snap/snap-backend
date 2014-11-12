class Game
  constructor: (@io) ->
    @players = []
    @maxScore = 10
    @gameLength = 120 * 1000
    @topic = "default"
    @start = false
    @timer = (ms, func) -> setTimeout func, ms
    @timerRunning = false

  setTopic: (topic) ->
    if not @start
      console.log "Setting Topic to: " + topic
      @topic = topic
      @io.sockets.emit "new topic", @topic

  startGame: () ->
    if not @start
      console.log "Starting Game"
      @start = true
      @timerRunning = true
      @io.sockets.emit "game started", { gameLength: @gameLength }
      callback = () =>
        @timerRunning = false
        @gameOver()
      @timer @gameLength, callback      

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)

  addWord: (player, word) ->
    # if moderator has not started the game
    # nobody can submit any words
    if not @start
      return

    word = word.toLowerCase().trim()

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

  winners: () ->
      winners = []
      maxScore = 0
      for p in @players
          if p.score > maxScore
              winners = []
              maxScore = p.score
          if p.score == maxScore
              winners.push p.name
      return winners

  gameOver: () ->
    @io.sockets.emit "game over",
      scores:({player: p.name, score: p.score} for p in @players)
      winners: @winners()
    @exportData()
    @start = false
    if @timerRunning
      clearTimeout(@timer)

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
    console.log '#### Game Data ####'
    console.log 'Topic: ' + @topic
    console.log 'Time: ' + process.hrtime()
    console.log(csv)

    @resetGame()

  resetGame: () ->
    console.log '... resetting game ...'
    for p in @players
      p.words = []
      p.snappedWords = []
      p.score = 0

  getWordCounts: () ->
    counts = {}
    for player in @players
      for word in player.words
        if word of counts
          counts[word] += 1
        else
          counts[word] = 1
    return counts

  getWords: () ->
      words = []
      for player in @players
          for word in player.words
              words.push word
      return words

module.exports = Game
