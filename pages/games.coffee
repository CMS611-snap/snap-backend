durationToString = (d) ->
  fixedWidth2 = (n) ->
    if n == 0
      return "00"
    if n < 10
      return "0" + n
    return n
  d.minutes = d.minutes || 0
  d.seconds = d.seconds || 0
  duration = ""
  if d.hours?
    duration += fixedWidth2(d.hours) + ":"
  duration += fixedWidth2(d.minutes)
  duration += ":" + fixedWidth2(d.seconds)
  return duration

module.exports = (app, DbHelper) ->
  if !DbHelper.db?
    app.get '/admin/*', (req, res) ->
      res.send "database disabled :("
  else
    app.get '/admin/games', (req, res) ->
      DbHelper.db
      .select(DbHelper.db.raw('games.id as id, games.started_at as started_at,
        games.topic as topic, games.facilitator as facilitator,
        games.location as location, games.event as event,
        games.num_players as players,
        COUNT(word_submissions.id) as word_count,
        (MAX(word_submissions.created_at) - MIN(word_submissions.created_at)) as length'))
      .from('games')
      .innerJoin('word_submissions', 'games.id', 'word_submissions.game_id')
      .groupBy('games.id')
      .orderBy('started_at', 'desc')
      .map (row) ->
        row.duration = durationToString(row.length)
        return row
      .then (content) ->
        res.render 'list',
          games: content
      .catch (error) ->
        console.log(error)

    app.get '/rpc/games/:ids/wordcloud', (req, res) ->
      ids = req.params.ids.split(',').map (e)->(parseInt e)
      DbHelper.db('word_submissions').whereIn('game_id', ids)
      .select(DbHelper.db.raw('word, COUNT(word) as frequency'))
      .groupBy('word')
      .map (row)->
        text: row.word
        frequency: row.frequency
      .then (content) ->
        res.send content
      .catch (error) ->
        console.log(error)

    app.get '/admin/games/:ids', (req, res) ->
      res.render 'game',
        ids: req.params.ids

    app.get '/admin/games/:id/trace.yaml', (req, res) ->
      id = parseInt req.params.id
      uniquePlayers = (words) ->
        players = {}
        for word in words
          players[word.player] = true
        player_list = []
        for player, _ of players
          player_list.push(player)
        return player_list

      DbHelper.db('word_submissions')
      .where('game_id', id)
      .select('user_uuid', 'word', 'created_at')
      .orderBy('created_at')
      .map (row) ->
        word: row.word
        player: row.user_uuid.toString()
        time: row.created_at
      .then (words) ->
        players = uniquePlayers(words)
        first_time = words[0].time
        last_time = words[words.length - 1].time
        for word in words
          word.time = word.time - first_time + 1000
        res.set {
          'Content-Type': 'text/yaml'
        }
        res.render 'trace',
          layout: false
          players: players.map (n) ->
            name: n
          words: words
          end_time: last_time + 1000
