var express = require('express'),
router  = express.Router(),
mongoose = require('mongoose'),
User = mongoose.model('User'),
Event = mongoose.model('Event');

var Util = require('../util/util');


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

router.param('_id', /^[0-9a-fA-F]{24}$/i);

// Page for creating a new Event
router.get('/new', Util.checkAuth, function(req, res) {

});

// New
// Submit new event
router.post('/new', Util.checkAuth, function(req, res, next) {

    // Using a placeholder for now. Will be required for next part
    // of the project
    var creator_id = mongoose.Schema.ObjectId();

    // Create a new event with all the request parameters
    var new_event = new Event({
        type: req.body.event_type,
        timestamp: req.body.event_time,
        creator: creator_id,
        group: [], // should we include the creator?
        latitude: req.body.event_lat,
        longitude: req.body.event_long,
        location_name: req.body.event_loc_name,
    });

    // Save it and check for errors
    new_event.save(function(err){
        if (err) {
          console.log(err);
          return next(err);
        }
        res.json({status: 'ok',
                 message: 'event saved',
                 event_id: new_event._id});
        res.end();
    });
});

// Serendipity
// Page for viewing the result of the serendipity button. Returns the
// closest event within an hour of the current time
router.get('/serendipity', Util.checkAuth, function(req, res) {

    var currentTime = new Date().getTime();
    const oneHour = 3600000;
    Event.find({ "timestamp": { $gt: currentTime,
                                $lt: currentTime + oneHour}},
                 function(err, docs){
       if (err) {
           next(err);
           return;
       }

       // Sort by distance to the user
       docs = Util.sortByDistance(docs, {latitude: 10.0, longitude: 10.0});
       json_res = docs[0];
       res.json(json_res);
   });
});

// Show
// Shows the event with the given id
router.get('/:_id', Util.checkAuth, function(req, res, next) {
    // Return the json of the single event
    Event.findOne({_id: req.originalUrl.split('/')[2]}, function(err, docs){
        if (err){
            next(err);
            return;
        }
        res.json(docs);
        res.end();
    });
});

// Update
// Update an event
router.patch('/:_id/', Util.checkAuth, function(req, res, next) {

    // get inputs, see what has actually changed.
    // (is there a better way to do this?)
    var fields_to_set = {
        type: req.body.event_type,
        timestamp: req.body.event_time,
        latitude: req.body.event_lat,
        longitude: req.body.event_long,
    };

    // Remove all non-null keys
    for (key in Object.keys(fields_to_set)){
        if (fields_to_set.key == null){
            delete fields_to_set.key;
        }
    }

    // find the event with this ID, created by the current user.
    // If no such event exists, there is an error.
    Event.findOneAndUpdate({_id: req.originalUrl.split('/')[2]},
                           {$set: fields_to_set},
                           function(e, s) {
       if (s == null){
           return next(e);
       }
       res.json({'Status' : 'OK', 'Message': 'Event updated'});
       res.end();
    })
});

// Add attendee
router.patch('/:_id/group', Util.checkAuth, function(req, res, next) {
    // how to make sure we aren't adding a duplicate user?
    Event.findOneAndUpdate(
        {_id: req.originalUrl.split('/')[2]},
        {$push: { group: req.body.new_attendee}},
        {safe: true, upsert: true},
        function(e, s){

            if (s == null) {
                return next(e);
            }

            res.json({'Status' : 'OK', 'Message': 'Event joined'});
            res.end();
        });
});

// Delete
// Deletes the event with the id in the url
router.delete('/:_id', Util.checkAuth, function(req, res, next){

    Event.findOne({_id: req.originalUrl.split('/')[2]})
         .remove(function(err) {
        if (err){
            return next(err);
        }
        res.redirect('/');
    })
});

// Get
// Web page showing relevant events, which are ordered by distance
// Relenvence is defined as all events from not until an hour later
//
// We are using a placeholder 10, 10 location because that will
// be handled through client interaction in the next part.
router.get('/', Util.checkAuth, function(req, res) {

    var currentTime = new Date().getTime();
    const oneHour = 3600000;
    Event.find({ "timestamp": { $gt: currentTime,
                                $lt: currentTime + oneHour }},
               function(err, docs) {
       if (err) {
           next(err);
           return;
       }
       docs = Util.sortByDistance(docs, {latitude: 10.0, longitude: 10.0});
       res.json(docs);
   });
});



module.exports = router;
