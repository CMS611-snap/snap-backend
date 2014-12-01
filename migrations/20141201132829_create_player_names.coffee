exports.up = (knex, Promise) ->
  return Promise.all [
    knex.schema.createTable 'users', (t)->
      t.increments()
      t.string 'name'
      t.uuid 'uuid'
      t.timestamp('created_at').defaultTo(knex.raw('now()'))
  ]

exports.down = (knex, Promise) ->
  return Promise.all [
    knex.schema.dropTable 'users'
  ]