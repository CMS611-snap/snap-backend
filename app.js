#!/usr/bin/env node

var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io')(server);
var port = process.env.PORT || 8080;

server.listen(port, function () {
  console.log('Server listening at port %d', port);
});


app.use(express.static(__dirname + '/public'));



////////////////////////////////////////////////////
// Models
require("coffee-script/register")

var Player = require('./models/player');

var Game = require('./models/game');
    game = new Game(io);

////////////////////////////////////////////////////
// Socket.io
io.on('connection', function (socket) {
  console.log("CONNECTION");

  socket.on('new player', function (playerName) {
    console.log("NEW PLAYER " + playerName);
    var player = new Player(0, socket, game, playerName);
    socket.player = player

    game.addPlayer(player);

    socket.emit('user joined', {
      player: socket.player.name,
    });
  });

  // when the client emits 'new message', this listens and executes
  socket.on('new word', function (word) {
    console.log("NEW WORD " + word);

    socket.emit('new word', {
      player: socket.player.name,
      word: word
    });

    game.addWord(socket.player, word);

  });

  // when the user disconnects.. perform this
  socket.on('disconnect', function () {
    ////////////////////////////
    // REMOVE PLAYER FROM GAME
    //
  });


});


module.exports = app;
