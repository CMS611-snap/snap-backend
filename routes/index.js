var express = require('express'),
    router  = express.Router();

require("coffee-script/register")

var Util = require('../models/util');

var Player = require('../models/player');

// Game is attached to req.game

router.post('/', Util.checkAuth, function(req, res, next) {
  var playerName = req.body.playerName;

  console.log("New Player: " + playerName);

  var newPlayer = new Player(playerName);
  req.game.addPlayer(newPlayer);

  res.json({response: "success"});
});


router.get('/', Util.checkAuth, function(req, res, next) {
  res.render('index.ejs');
});



module.exports = router;
