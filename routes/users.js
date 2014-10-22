var express = require('express');
var router = express.Router();
var bcrypt = require('bcrypt');
var sillyName = require('sillyname');
var _ = require('lodash');

var mongoose = require('mongoose');
var User = mongoose.model('User');

var Util = require('../util/util');

router.get('/', Util.checkAuth, function(req, res, next) {

    User.find({}, {_id: 0, password: 0}).exec(function(err, docs) {
        res.json(docs);
        res.end();
    });
});

router.get('/new', function(req, res, next) {
    // TODO
    // res.render('users/new', { title: 'Add New User' });
});

router.post('/create', function(req, res, next) {

    if(req.body.email.length == 0) {
        res.end("Email must be filled.");
        return;
    }
    if(req.body.password.length == 0) {
        res.end("Password must be filled.");
        return;
    }

    bcrypt.genSalt(10, function(err, salt) {
      bcrypt.hash(req.body.password, salt, function(err, hash) {

        var silly_name = sillyName();

        // Store hash in your password DB.
        var user = new User({
          identifier: silly_name,
          password: hash,
          email: req.body.email
        });
        user.save(function(err) {
            if(err) {
              res.json({status: 'not ok', message: 'user already exists'});
              res.end();

            } else {
                res.json({status: 'ok', message: 'user created'});
                res.end();
            }
        });
      });
    });
});

router.delete('/', Util.checkAuth, function(req, res, next) {
    var auth = req.session.user;

    User.findOne({ _id: auth._id }).remove(function(err) {
	if(err) {
	    console.log(err);
	    return next(err);
	}
	res.json({status: 'ok', message: 'user deleted'});
	res.end();
    });
});

router.get('/login', function(req, res, next) {
    // TODO
    // res.render('users/login', {title: 'Login'});

});

router.post('/login', function(req, res, next) {

    User.findOne({ email: req.body.email }, function(err, doc) {
        if(err) next(err);

        if(doc == null) {
            res.json({status: 'not ok',
                     message: "Username or password invalid" });
	    res.end();
        } else {

            bcrypt.compare(req.body.password,
                           doc.password,
                           function(err, auth) {
                if(err)
                    next(err);

                if(auth) {
                    req.session.user = {_id: doc._id,
                                        email: doc.email,
                                        identifier: doc.identifier};
                    res.json({status: 'ok'});
                    res.end();
                }
                else {
                    res.json({status: 'not ok',
                             message: 'Username or password invalid'});
                    res.end();

                }

            });
        }
    });


});

router.get('/logout', function(req, res, next) {
    if(req.session.user)
        delete req.session.user;
    res.json({status: 'ok'});
    res.end();
});

router.param(function(name, fn){
    if (fn instanceof RegExp) {
        return function(req, res, next, val){
            var captures;

            if (captures = fn.exec(String(val))) {
                req.params[name] = captures[0];
                next();
            } else {
                next('route');
            }
        }
    }
});

router.param('identifier', /^[a-zA-Z0-9_]+$/i);

router.get('/:identifier', Util.checkAuth, function(req, res, next) {
    var auth = req.session.user;

    User.findOne({ identifier: req.params.identifier },
                 {_id: 0, password: 0}).exec(function(err, doc) {
        if(err)
	       return next(err);
        if(doc == null) {
            res.json({status: "not ok"});
            res.end();
        } else {
	    res.json(doc);
	    res.end();
        }
    });
});

module.exports = router;
