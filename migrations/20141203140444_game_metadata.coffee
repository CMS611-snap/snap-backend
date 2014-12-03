# vim: ts=2:sw=2

exports.up = (knex, Promise) ->
  return Promise.all [
    knex.schema.table 'games', (t) ->
      t.string 'facilitator'
      t.string 'location'
      t.string 'event'
      t.integer 'num_players'
  ]


exports.down = (knex, Promise) ->
  return Promise.all [
    knex.schema.table 'games', (t) ->
      t.dropColumn 'facilitator'
      t.dropColumn 'location'
      t.dropColumn 'event'
      t.dropColumn 'num_players'
  ]
