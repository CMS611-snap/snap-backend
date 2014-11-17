module.exports = (app, DbHelper) ->
  return if !DbHelper.db?
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


  app.get '/admin/games/:id', (req, res) ->
    id = parseInt req.params.id
    DbHelper.db('word_submissions').where({game_id: id})
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
