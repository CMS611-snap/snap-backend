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
        COUNT(word_submissions.id) as word_count'))
      .from('games')
      .innerJoin('word_submissions', 'games.id', 'word_submissions.game_id')
      .groupBy('games.id')
      .orderBy('started_at', 'desc')
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
