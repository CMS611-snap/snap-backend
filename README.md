snap-backend
============

#Setup
####Start
```
npm install
npm start
```

You should run `npm install` whenever we add modules to package.json. In
practice, if something fails in `npm start`, re-run `npm install` and see if
that fixes it.

#### Code
Almost all code that you write will be restricted to `models/game.coffee`,
`models/player.coffee` and `app.js`.

API
====

# socket.io events

## Moderators

### start game
Starts the current game.

### stop game
Stops the current game.

### set topic
Sets the topic on the current game, changing it if the game is in progress.

## Player events (to the game)

### new player
        "<name>"

### new word
        "<word>"

Does nothing if the game has not started. Otherwise, adds the word to the
player's list and sends out snaps. Also triggers a `wordcloud` broadcast.

### disconnect

Not a real message, automatically sent when the client leaves (eg, the player
closes or refreshes the browser).

Does nothing.

## Game events (to players/moderators)

### user joined
        {player: "<name>"}

Currently broken, echoed back in response to `new player`.

### new word
        {player: "<name>",
         word: "<word>"}

Currently broken, echoed back to the player.

### snap
       {player: "<other player name>",
        d_score: <change in score>,
        word: "<word>"}

Sent when you snap with someone. One other player's name is given (somewhat
arbitrarily from the list of players you snapped with). `d_score` is intended
to be a delta score (for example, to get multiple points for more frequent
words). It is currently always 1.

TODO: support multiple snaps, either by listing all the player names and
setting `d_score` to the number of other players, or by sending multiple snap
events.

### wordcloud
        {words: [{text: "<word>",
                  size: numUses * multiplier,
                  score: numUses}...],
         multiplier: multiplier}

This is sent on every word.

TODO: send only to the moderator to make this more efficient.

### new topic
        "<topic>"

### game started
        {gameLength: <game length in milliseconds, or 0 for no time limit>,
         elapsed: <elapsed time in milliseconds>,
         players: ["<name>"...]}

Sent when game is started (moderator sends `start game`) and when a player
joins if the game has already started.

TODO: send what the game ending conditions are when relevant (eg, no need to
display the timer if the game is untimed, while knowing the maximum number of
words is useful).

TODO: The list of players likely includes extra players that have disconnected
permanently. We should remove those players while still potentially allowing
for temporary disconnects from players still in the game.

### scores
        {scores: [{player: "<name>", score: score}...],
         myScore: score}

Sent to everyone after every `new player` and `new word` event. The scores
array includes everyone's score, sorted by score in descending order. myScore
is customized for each player and has that player's score.

This was intended for displaying two scores in the mobile version (your score
and the top score, or second highest if you have the top score).

### game over
        {scores: [player: "<name>", score: score}...],
         winners: ["<winner name>"...]}

The game currently ends only when `stop game` is sent by a moderator.

Both scores and winners are sent. The winner logic might not be as simple as
the top scores (for example, Pablo suggested not scoring for the most frequent
or least frequent words).

TODO: make the game ending conditions configurable, and send why the game ended.

# HTTP calls (RPC interface)

## GET /rpc/words
        ["<word>"...]

Just gets a list of all words submitted, with duplicates.

## GET /rpc/wordcounts
        {"<word>": count...}

The keys are words and the values are how many players submitted that word.

## GET /rpc/wordcloud
        {words: [{text: "<word>",
                  size: numUses * multiplier,
                  score: numUses}...],
         multiplier: multiplier}
        
Identical to the `wordcloud` broadcast message. This lets the moderator
interface display the wordcloud when the page is refreshed rather than wait for
a new word or player to join to trigger that event.
