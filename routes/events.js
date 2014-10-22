var express = require('express'),
    router  = express.Router();

var mongoose = require('mongoose'),
    User = mongoose.model('User'),
    Event = mongoose.model('Event');

var Util = require('../util/util');


router.get('/', Util.checkAuth, function(req, res, next) {

});


module.exports = router;
