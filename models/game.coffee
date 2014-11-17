class Game
  constructor: (@io, @DbHelper, endConfig) ->
    @players = []
    @maxScore = endConfig.maxScore || null
    @gameLength = (endConfig.maxSeconds || 0) * 1000
    if @gameLength == 0
        @gameLength = null
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

  addWord: (player, word) ->
    # if moderator has not started the game
    # nobody can submit any words
    if not @start
      return

    word = word.toLowerCase().trim()

    #Reject word if already guessed by player
    if player.hasGuessed(word)
      return

    #Add the submission to db
    @DbHelper.addWordSubmission @gameId, player.uuid, word, (word_index)=>
      snapped = false
      for p in @players
        if p.hasGuessed(word)
          snapped = true
          if not p.hasSnapped(word)
            p.sendSnap(word, 1)

      if snapped
        player.sendSnap(word, 1)

        #add the snap event to db
        @DbHelper.addEvent @gameId, word_index, player.uuid, {type: @DbHelper.eventType.snap}


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
