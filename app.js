#!/usr/bin/env node
var express = require('express');
var exphbs = require('express-handlebars');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io')(server);
var port = process.env.PORT || 8080;
require("coffee-script/register")

app.engine('handlebars', exphbs({defaultLayout: 'main'}));
app.set('view engine', 'handlebars');

server.listen(port, function () {
  console.log('Server listening at port %d', port);
});

////////////////////////////////////////////////////
// Database stuff

DbHelper = require('./helpers/db_helper')

////////////////////////////////////////////////////
// Models
var Player = require('./models/player');

var Game = require('./models/game');
    game = new Game(io, DbHelper);

////////////////////////////////////////////////////
// RPC methods
app.get('/rpc/words', function(req, res) {
    res.send(game.getWords());
});

// Returns a list dictionary { word: count, ...}
app.get('/rpc/wordcounts', function(req, res) {
    res.send(game.getWordCounts());
});

require('./pages/games.coffee')(app, DbHelper);

app.use('/', express.static(__dirname + '/public'));

////////////////////////////////////////////////////
// Socket.io
io.on('connection', function (socket) {
  console.log("CONNECTION");

  socket.on('start game', function () {
    game.startGame();
  });
  
  socket.on('set topic', function(topic) {
    game.setTopic(topic);
  });

  socket.on('new player', function (playerName) {
    console.log("PLAYER " + playerName);
    var player = new Player(0, socket, game, playerName);
    socket.player = player

    debugger;

    game.addPlayer(player);

    socket.emit('user joined', {
      player: socket.player.name,
    });
  });

  // when the client emits 'new message', this listens and executes
  socket.on('new word', function (word) {

    game.addWord(socket.player, word);
   
    if (game.start) {
    console.log("WORD " + word);
    socket.emit('new word', {
      player: socket.player.name,
      word: word
    });

    var multiplier = 10;
    var words = game.getWordCounts();
    var wordCounts = [];
    for (countedWord in words) {
      wordCounts.push({text: countedWord,
                       size: words[countedWord] * multiplier,
                       score: words[countedWord]});
                       //size: Math.sqrt(words[countedWord] * 200)});
    }

    // TODO(sam): this is a hack to get the moderator interface to work; we
    // should have moderators join like any player and notify only moderator
    // sockets
    io.sockets.emit('wordcloud', {
      words: wordCounts,
      multiplier: multiplier
    });
  }

  });

  // when the user disconnects.. perform this
  socket.on('disconnect', function () {
    ////////////////////////////
    // REMOVE PLAYER FROM GAME
    //
  });
});

module.exports = app;
