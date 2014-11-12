module.exports =
  eventType:
    snap: 0
    score: 1

  createGame: (db, topic, cb) ->
    db('games')
    .returning('id')
    .insert
      started_at: db.raw('now()')
      topic: topic
    .then (ans)->
      cb(ans[0])

  stopGame: (db, index) ->
    if index?
      db('games').where('id', index).update({ ended_at: db.raw('now()') }).exec()

  addWordSubmission: (db, game_id, uuid, word, cb) ->
    return if !game_id?
    db('word_submissions')
    .returning('id')
    .insert
      game_id: game_id
      user_uuid: uuid
      word: word
    .then (ans) ->
      cb ans[0]

  addEvent: (db, game_id, word_index, uuid, params) ->
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

