#!/usr/bin/env node

// General libraries used
//var express      = require('express'),
    //path         = require('path'),
    //favicon      = require('serve-favicon'),
    //logger       = require('morgan'),
    //cookieParser = require('cookie-parser'),
    //bodyParser   = require('body-parser'),
    //session      = require('express-session'),
    //helpers      = require('express-helpers');








var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io')(server);
var port = process.env.PORT || 3000;

server.listen(port, function () {
  console.log('Server listening at port %d', port);
});


app.use(express.static(__dirname + '/public'));


console.log("dir: " + __dirname);

////////////////////////////////////////////////////
// Models
require("coffee-script/register")

var Player = require('./models/player');

var Game = require('./models/game');
    game = new Game();


////////////////////////////////////////////////////
// Socket.io
io.on('connection', function (socket) {
    console.log("CONNECTION");

  socket.on('new player', function (playerName) {
    console.log("NEW PLAYER");
    var player = new Player(playerName);

    socket.player = player;
    game.addPlayer(player);

    socket.emit('login', {
    });

    socket.broadcast.emit('user joined', {
      player: socket.player,
    });
  });

  // when the client emits 'new message', this listens and executes
  socket.on('new word', function (data) {

    socket.broadcast.emit('new word', {
      player: socket.player,
      word: data
    });
  });

  // when the user disconnects.. perform this
  socket.on('disconnect', function () {
    ////////////////////////////
    // REMOVE PLAYER FROM GAME
    //

    // echo globally that this client has left
    socket.broadcast.emit('player left', {
      player: socket.player,
    });
  });


});















module.exports = app;
