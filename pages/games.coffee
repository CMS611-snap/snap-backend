module.exports = (app, DbHelper) ->
  if !DbHelper.db?
    app.get '/admin/*', (req, res) ->
      res.send "database disabled :("
  else
    app.get '/admin/games', (req, res) ->
      DbHelper.db('games').select(['id', 'topic', 'started_at']).orderBy('started_at', 'desc').map (row)->
        "<a href='/admin/games/#{row.id}'>#{row.topic} - #{row.started_at}"
      .reduce((content, row) ->
        return content + row + ' <br> '
      , '')
      .then (content) ->
        res.send(content)
      .catch (error) ->
        console.log(error)

    app.get '/admin/games/:ids', (req, res) ->
      ids = req.params.ids.split(',').map (e)->(parseInt e)
      DbHelper.db('word_submissions').whereIn('game_id', ids)
      .select(DbHelper.db.raw('word, COUNT(word) as frequency'))
      .groupBy('word')
      .map (row)->
        {text: row.word, size: row.frequency * 10}
      .then (content) ->
        # res.send JSON.stringify(content)
        res.render 'game',
          words: content
          helpers:
            json: (val)-> JSON.stringify(val)
      .catch (error) ->
        console.log(error)
