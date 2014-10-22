var express = require('express'),
    router  = express.Router();

var io = require('socket.io')(require('http').Server(express()));

var Util = require('../models/util');

var Game = require('../models/game'),
    game = Game();


router.get('/', Util.checkAuth, function(req, res, next) {
  //res.json({response: "hello"});
  res.render('index.ejs');
});


io.on('connection', function(socket){
  console.log('a user connected');
});

module.exports = router;
