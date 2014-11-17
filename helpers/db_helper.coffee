configs = require('../knexfile.coffee')
switch process.env.NODE_ENV
  when 'production' then config = configs.production
  when 'dev_db' then config = configs.development
  else
    config = null
    console.log 'The database could not be reached. Data will not be stored.'

db = if config? then require('knex')(config) else null

module.exports =
  db: db
  eventType:
    snap: 0
    score: 1

  createGame: (topic, cb) ->
    if !db?
      cb(null)
      return
    db('games')
    .returning('id')
    .insert
      started_at: db.raw('now()')
      topic: topic
    .then (ans)->
      cb(ans[0])

  stopGame: (index) ->
    return if !db?
    if index?
      db('games').where('id', index).update({ ended_at: db.raw('now()') }).exec()

  addWordSubmission: (game_id, uuid, word, cb) ->
    if !db?
      cb(null)
      return
    return if !game_id?
    db('word_submissions')
    .returning('id')
    .insert
      game_id: game_id
      user_uuid: uuid
      word: word
    .then (ans) ->
      cb ans[0]

  addEvent: (game_id, word_index, uuid, params) ->
    return if !db?
    return if !game_id?
    return if !params.type?
    params.extra_1 ?= null
    params.extra_2 ?= null

    db('events').insert
      game_id: game_id
      user_uuid: uuid
      word_submission_id: word_index
      type: params.type
      extra_1: params.extra_1
      extra_2: params.extra_2
    .exec()

