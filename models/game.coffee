# vim: ts=2:sw=2
class Game
  constructor: (@io, @DbHelper) ->
    @players = []
    @topic = "default"
    @start = false
    @setEndConfig
      maxScore: null
      maxSeconds: null
      maxWords: null
    @metadata =
      facilitator: null
      location: null
      event: null
      num_people: null
    @startTime = null
    @timer = null
    @gameId = null
    @_sendScoreInterval = null
    @snapHistory = []

  setEndConfig: (endConfig) ->
    @endConfig = endConfig
    parseNum = (num) ->
      if num && num != 0 && !isNaN(num)
        return num
      return null
    @maxScore = parseNum(endConfig.maxScore)
    gameLengthSeconds = parseNum(endConfig.maxSeconds)
    if gameLengthSeconds
      @gameLength = gameLengthSeconds * 1000
    else
      @gameLength = null
    @maxWords = parseNum(endConfig.maxWords)

  setTopic: (topic) ->
    if not @start
      console.log "Setting Topic to: " + topic
      @topic = topic
      @io.sockets.emit "new topic", @topic

  sendGameStarted: (socket) ->
      elapsed = Date.now() - @startTime
      socket.emit "game started",
          gameLength: @gameLength
          maxScore: @maxScore
          maxWords: @maxWords
          elapsed: elapsed
          players: (player.identifier() for player in @players)
          topic: @topic

  startGame: () ->
    if not @start
      console.log "Starting Game"
      @start = true
      @startTime = Date.now()

      # insert the game to db
      @DbHelper.createGame @topic, @metadata, (res)=>
        @gameId = res

      @sendGameStarted(@io.sockets)
      if @gameLength
          console.log "starting timer for #{@gameLength/1000}"
          cb = () =>
              @gameOver()
          @timer = setTimeout(cb, @gameLength)

      @_sendScoreInterval = setInterval () =>
        @sendScores()
      , 2000

  addPlayer: (newPlayer) ->
    @players.push(newPlayer)
    if @start
      @sendGameStarted(newPlayer.socket)

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
      snapped = []
      for p in @players
        if p.hasGuessed(word)
          snapped.push p
          # if not p.hasSnapped(word)
          #   p.sendSnap(word, 1, player.name)

      # console.log snapped
      if snapped.length > 0
        snapped.push player

        snapped_names = snapped.map (p)-> p.identifier()

        @snapHistory.push
          players: snapped_names
          word: word

        for p in snapped
          if not p.hasSnapped(word)
            p.sendSnap(word, 1, snapped_names)

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
          winners.push p.identifier()
      return winners

  scores: () ->
    playerScores = []
    for p in @players
      playerScores.push
        player: p.identifier()
        score: p.score
      playerScores.sort (a, b) ->
        scoreDiff = b.score - a.score
        if scoreDiff != 0
          return scoreDiff
        if a.player.name < b.player.name
          return -1
        if a.player.name > b.player.name
          return 1
        return 0
    return playerScores

  sendScores: () ->
    scores = @scores()
    @io.sockets.emit "scores",
      scores: @scores()
      snaps: @snapHistory

    @snapHistory = []

  gameOver: () ->
    console.log "Ending game"
    @io.sockets.emit "game over",
      scores: @scores()
      winners: @winners()
    @exportData()
    @start = false
    clearTimeout(@timer)
    clearInterval(@_sendScoreInterval)

  exportData: () ->
    freq = {}
    for p in @players
      for word of p.words
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
    @players = @players.filter (p) -> p.connected
    for p in @players
      p.reset()

  getWordCounts: () ->
    counts = {}
    for player in @players
      for word of player.words
        if word of counts
          counts[word] += 1
        else
          counts[word] = 1
    return counts

  getWords: () ->
    words = []
    for player in @players
      for word of player.words
        words.push word
    return words

module.exports = Game
