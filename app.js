#!/usr/bin/env node
var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io')(server);
var port = process.env.PORT || 8080;

server.listen(port, function () {
  console.log('Server listening at port %d', port);
});

////////////////////////////////////////////////////
// Models
require("coffee-script/register")

var Player = require('./models/player');

var Game = require('./models/game');
    game = new Game(io);


////////////////////////////////////////////////////
// Globals
var game_started = false;
var game_length = 60 * 1000; // 60 seconds
//var game_length = 6 * 1000;

////////////////////////////////////////////////////
// RPC methods
app.get('/rpc/words', function(req, res) {
    res.send(game.getWords());
});

app.use('/', express.static(__dirname + '/public'));

////////////////////////////////////////////////////
// Socket.io
io.on('connection', function (socket) {
  console.log("CONNECTION");

  socket.on('new player', function (playerName) {
    console.log("PLAYER " + playerName);
    var player = new Player(0, socket, game, playerName);
    socket.player = player

    game.addPlayer(player);

    socket.emit('user joined', {
      player: socket.player.name,
    });
  });

  // when the client emits 'new message', this listens and executes
  socket.on('new word', function (word) {
    console.log("WORD " + word);

    if ( ! game_started) {
      setTimeout(function() {
        var scores = [];
        for (player in game.players) {
          scores.push({player: player.name,
                       score: player.score});
        }
        socket.emit('game over', {
          scores: scores
        });
      }, game_length);
    }

    socket.emit('new word', {
      player: socket.player.name,
      word: word
    });

    game.addWord(socket.player, word);

    var words = game.getWordCounts();
    var wordCounts = [];
    for (countedWord in words) {
      wordCounts.push({text: countedWord,
                       size: Math.sqrt(words[countedWord] * 200)});
    }

    socket.emit('wordcloud', {
      words: wordCounts
    });

  });

  // when the user disconnects.. perform this
  socket.on('disconnect', function () {
    ////////////////////////////
    // REMOVE PLAYER FROM GAME
    //
  });
});

module.exports = app;
