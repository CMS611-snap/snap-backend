var express = require('express'),
    router  = express.Router();

var mongoose = require('mongoose');
var User = mongoose.model('User');

var Util = require('../util/util');


router.get('/', Util.checkAuth, function(req, res, next) {
});


module.exports = router;
