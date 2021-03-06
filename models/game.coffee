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
    @wordSubmissionHistory = []

  setEndConfig: (endConfig) ->
    @endConfig = endConfig
    parseNum = (num) ->
      num = parseInt(num)
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
    console.log "End conditions: score: #{@maxScore} length: #{@gameLength} words: #{@maxWords}"

  setTopic: (topic) ->
    if not @start
      console.log "Setting Topic to: " + topic
      @topic = topic
      @io.sockets.emit "new topic", @topic

  sendGameStarted: (socket) ->
      elapsed = Date.now() - @startTime
      socket.emit "game started",
          gameId: @gameId
          gameLength: @gameLength
          maxScore: @maxScore
          maxWords: @maxWords
          elapsed: elapsed
          players: (player.identifier() for player in @players when player.connected)
          topic: @topic

  startGame: () =>
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
    newPlayer.socket.emit 'Player ID', newPlayer.identifier()
    if not newPlayer?
      return
    @players.push(newPlayer)
    if @start
      @io.sockets.emit "userJoin",
        identifier: newPlayer.identifier()
      @sendGameStarted(newPlayer.socket)

  # cb will be passed error, snap, where snap is the same format as the 'snap'
  # socket event
  addWord: (player, word, cb) ->
    # if moderator has not started the game
    # nobody can submit any words
    if not @start
      cb("game not started", null)
      return

    # TODO(tchajed): debug this, though it seems to only occur when rebooting
    # server while frontends our still open
    if not player
      cb("no player", null)
      return

    word = word.toString().toLowerCase().trim()

    #Reject word if already guessed by player
    if player.hasGuessed(word)
      cb("duplicate", null)
      return

    if @maxWords and player.word_count >= @maxWords
      cb("max words", null)
      return

    #Add the submission to db
    @DbHelper.addWordSubmission @gameId, player.uuid, word, (word_index)=>
      @wordSubmissionHistory.push
        player: player.identifier()
        word: word

      snapped = []
      for p in @players
        if p.hasGuessed(word)
          snapped.push p

      player.addWord(word)

      playerSnap = null
      if snapped.length > 0
        snapped.push player
        snapped_names = snapped.map (p)-> p.identifier()

        @snapHistory.push
          players: snapped_names
          word: word

        for p in snapped
          if p.uuid == player.uuid
            playerSnap = p.snapEvent(word, snapped.length - 1, snapped_names)
          else
            event = p.snapEvent word, 1, [player.identifier()]
            p.sendSnap event

        #add the snap event to db
        @DbHelper.addEvent @gameId, word_index, player.uuid, {type: @DbHelper.eventType.snap}

      if @isGameOver()
        # send this with a delay to make sure players receive their final point
        # before the game over message
        setTimeout () =>
          @gameOver()
        , 500
      cb(null, playerSnap)

  reachedMaxScore: () ->
    if not @maxScore
      return false
    for p in @players when p.connected
      if p.score >= @maxScore
        return true
    return false

  reachedMaxWords: () ->
    if not @maxWords
      return false
    for p in @players when p.connected
      if p.word_count < @maxWords
        return false
    return true

  isGameOver: () ->
    @reachedMaxScore() || @reachedMaxWords()

  winners: () ->
      winners = []
      maxScore = 0
      for p in @players when p.connected
        if p.score > maxScore
          winners = []
          maxScore = p.score
        if p.score == maxScore
          winners.push p.identifier()
      return winners

  scores: () ->
    playerScores = []
    for p in @players when p.connected
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
      wordSubmissions: @wordSubmissionHistory

    @snapHistory = []
    @wordSubmissionHistory = []

  gameOver: () ->
    console.log "Ending game"
    @io.sockets.emit "game over",
      gameId: @gameId
      scores: @scores()
      winners: @winners()
    @exportData()
    @start = false
    clearTimeout(@timer)
    clearInterval(@_sendScoreInterval)

  exportData: () ->
    freq = {}
    for p in @players when p.connected
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
    @players = (p for p in @players when p.connected)
    for p in @players
      p.reset()

  getWordCounts: () ->
    counts = {}
    # include disconnected players as well
    for player in @players
      for word of player.words
        if word of counts
          counts[word] += 1
        else
          counts[word] = 1
    return counts

  getWords: () ->
    words = []
    # include disconnected players as well
    for player in @players
      for word of player.words
        words.push word
    return words

module.exports = Game
