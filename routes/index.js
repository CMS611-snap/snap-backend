var express = require('express'),
    router  = express.Router();

var Util = require('../models/util');

var Game = require('../models/game'),
    game = Game();


router.get('/', Util.checkAuth, function(req, res, next) {
  res.json({response: "hello"});
});


module.exports = router;
