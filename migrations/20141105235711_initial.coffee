exports.up = (knex, Promise) ->
  return Promise.all [
    knex.schema.createTable 'games', (t)->
      t.increments()
      t.dateTime 'started_at'
      t.dateTime 'ended_at'
      t.timestamps()
    knex.schema.createTable 'words', (t)->
      t.increments()
      t.string('word').index 'word_idx'
      t.timestamp('created_at').defaultTo(knex.raw('now()'))
      
    # each submitted word is an action
    knex.schema.createTable 'actions', (t)->
      t.increments()
      t.integer('game_id').index 'game_id_idx'
      t.integer('word_id').index 'word_id_id' # id of the word submitted
      t.uuid 'user_uuid' # unique id generated on each join

      t.integer 'snapped_id' # id of the word snapped with (null if not a snap)
      t.integer 'snapped_order' # which snap of the same word this is (null if not a snap)
      t.decimal 'score' # score awarded for an action
      t.timestamp('created_at').defaultTo(knex.raw('now()'))
  ]


exports.down = (knex, Promise) ->
  return Promise.all [
    knex.schema.hasTable('games').then (e)->
      if e then knex.schema.dropTable 'games'
    knex.schema.hasTable('words').then (e)->
      if e then knex.schema.dropTable 'words'
    knex.schema.hasTable('actions').then (e)->
      if e then knex.schema.dropTable 'actions'
  ]
