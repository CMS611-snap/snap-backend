var express = require('express'),
    router  = express.Router();

require("coffee-script/register")

var io = require('socket.io')(require('http').Server(express()));

var Util = require('../models/util');

var Game = require('../models/game');
    game = Game();

var Player = require('../models/player');

router.post('/newplayer', Util.checkAuth, function(req, res, next) {
  //var playerName = req.body.playerName;

  //var newPlayer = new Player(playerName);
  //game.addPlayer(newPlayer);

  res.json({response: "success"});
});


router.get('/', Util.checkAuth, function(req, res, next) {
  res.render('index.ejs');
});



io.on('connection', function(socket){
  console.log('a user connected');
});

module.exports = router;
