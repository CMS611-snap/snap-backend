class Game
  constructor: (@io, @DbHelper, endConfig) ->
    @players = []
    @maxScore = endConfig.maxScore || null
    @gameLength = (endConfig.maxSeconds || 0) * 1000
    if @gameLength == 0
        @gameLength = null
    @maxWords = endConfig.maxWords || null
    @topic = "default"
    @start = false
    @timer = null
    @gameId = null

  setTopic: (topic) ->
    if not @start
      console.log "Setting Topic to: " + topic
      @topic = topic
      @io.sockets.emit "new topic", @topic

  startGame: () ->
    if not @start
      console.log "Starting Game"
      @start = true
      @startTime = Date.now()

      # insert the game to db
      @DbHelper.createGame @topic, (res)=>
        @gameId = res

      @io.sockets.emit "game started", { gameLength: @gameLength }
      if @gameLength
          cb = () =>
              @gameOver()
          @timer = setTimeout(cb, @gameLength)
    

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)
    if @start
      # TODO: indicate how long ago game started
      newPlayer.socket.emit "game started", { gameLength: @gameLength }

  addWord: (player, word) ->
    # if moderator has not started the game
    # nobody can submit any words
    if not @start
      return

    # TODO(tchajed): debug this, though it seems to only occur when rebooting
    # server while frontends our still open
    if not player
      return

    word = word.toLowerCase().trim()

    #Reject word if already guessed by player
    if player.hasGuessed(word)
      return

    #Add the submission to db
    @DbHelper.addWordSubmission @gameId, player.uuid, word, (word_index)=>
      snappedWith = null
      for p in @players
        if p.hasGuessed(word)
          snappedWith = p.name
          if not p.hasSnapped(word)
            p.sendSnap(word, 1, player.name)

      if snappedWith
        player.sendSnap(word, 1, snappedWith)

        #add the snap event to db
        @DbHelper.addEvent @gameId, word_index, player.uuid, {type: @DbHelper.eventType.snap}


      player.addWord(word)

      if @isGameOver()
        @gameOver()


  reachedMaxScore: () ->
    if not @maxScore
      return false
    for p in @players
      if p.score >= @maxScore
        return true
    return false

  reachedMaxWords: () ->
    if not @maxWords
      return false
    for p in @players
      if p.words.length < @maxWords
        return false
    return true

  isGameOver: () ->
    @reachedMaxScore() || @reachedMaxWords()

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

  scores: () ->
    playerScores = []
    for p in @players
      playerScores.push
        player: p.name
        score: p.score
      playerScores.sort (a, b) ->
        scoreDiff = b.score - a.score
        if scoreDiff != 0
          return scoreDiff
        if a.name < b.name
          return -1
        if a.name > b.name
          return 1
        return 0
    return playerScores

  sendScores: () ->
    scores = @scores()
    for p in @players
      p.socket.emit "scores",
        scores: scores
        myScore: p.score

  gameOver: () ->
    @io.sockets.emit "game over",
      scores:({player: p.name, score: p.score} for p in @players)
      winners: @winners()
    @exportData()
    @start = false
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

    # write to db
    @DbHelper.stopGame @gameId

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
