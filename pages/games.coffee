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
          players[word.user_uuid] = word.user_name
        player_list = []
        for uuid, name of players
          player_list.push
            uuid: uuid
            name: name
        return player_list

      DbHelper.db
      .where('game_id', id)
      .select(DbHelper.db.raw('word_submissions.user_uuid as user_uuid,
        users.name as user_name,
        word_submissions.word as word,
        word_submissions.created_at as created_at'))
      .from('word_submissions')
      .innerJoin('users', 'word_submissions.user_uuid', 'users.uuid')
      .orderBy('created_at')
      .map (row) ->
        user_uuid: row.user_uuid
        user_name: row.user_name
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
          players: players
          words: words
          end_time: last_time + 1000
      .catch (error) ->
        console.error(error)
