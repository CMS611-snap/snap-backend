exports.up = (knex, Promise) ->
  return Promise.all [
    knex.schema.createTable 'games', (t)->
      t.increments()
      t.dateTime 'started_at'
      t.dateTime 'ended_at'
      t.string 'topic'

    knex.schema.createTable 'word_submissions', (t)->
      t.increments()
      t.integer('game_id').notNullable().index 'w_game_id_idx'
      t.uuid 'user_uuid'
      t.string('word').notNullable()
      t.timestamp('created_at').defaultTo(knex.raw('now()'))

    knex.schema.createTable 'events', (t)->
      t.increments()
      t.integer('game_id').notNullable().index 'e_game_id_idx'
      t.integer('word_submission_id').index 'word_submission_id_idx' # id of the word submission. Nullable.
      t.uuid 'user_uuid' # unique id generated on each join
      t.integer('type').notNullable()
      t.integer 'extra_1'
      t.integer 'extra_2'
      t.timestamp('created_at').defaultTo(knex.raw('now()'))
  ]


exports.down = (knex, Promise) ->
  return Promise.all [
    knex.schema.hasTable('games').then (e)->
      if e then knex.schema.dropTable 'games'
    knex.schema.hasTable('word_submissions').then (e)->
      if e then knex.schema.dropTable 'word_submissions'
    knex.schema.hasTable('events').then (e)->
      if e then knex.schema.dropTable 'events'
  ]
