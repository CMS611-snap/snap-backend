// This testing file assumes that user with
// email "test@mit.edu" with password "123" exists.

// Set autostart to false so we can have setup
// before async tests start running
// QUnit.config.autostart = false;

module( "Users Testing while Not Authenticated" );

asyncTest("User Create", function() {
    expect(1);
    $.post('/users/create',
           { email: "create@mit.edu", password: "123" },
           function (data) {

               equal(data.status, "ok", "Create create@mit.edu");

               // Always start test here
               start();

           }).fail(function() {
               ok(false, "Received status 500");
               // start here too in case ajax fails and
               // previous callback is not called
               start();
           });
});
asyncTest("User Delete", function() {
    expect(2);
    $.post('/users/login',
           { email: "create@mit.edu", password: "123" },
           function (data) {

               equal(data.status, "ok", "Login as create@mit.edu");

               $.ajax({
                   url: '/users',
                   type: 'DELETE',
                   success: function(data) {
                       equal(data.status, "ok", data.message);

                       // Always start test here
                       start();
                   }
               });
           }).fail(function() {
               ok(false, "Received status 500");

               // start here too in case ajax fails and
               // previous callback is not called
               start();
           });
});


asyncTest("User Login", function() {
    expect(1);
    $.post('/users/login',
           { email: "test@mit.edu", password: "123" },
           function (data) {

               equal(data.status, "ok", "Login as test@mit.edu");

               // Always start test here
               start();

           }).fail(function() {
               ok(false, "Received status 500");

               // start here too in case ajax fails and
               // previous callback is not called
               start();
           });
});


module( "Users Testing while Authenticated", {
    // runs before each test

    setup: function() {
        // Let's stop tests, otherwise tests may run while we login (ajax)
        var self = this;
        stop();
        $.post('/users/login',
               { email: 'test@mit.edu', password: '123' },
               function(res) {
                   equal(res.status, 'ok', 'Login');

                   if(res.status == 'ok') {
		       console.dir(res);
                       self.identifier = res.identifier;
                       console.log("Logged in");
                       start();
                   }
               });
        // ajax calls
    },
    // runs after each test
    teardown: function() {
        $.getJSON('/users/logout', function (data) {
            // Assumes it returns okay (needs to check)
        });
    }
});


asyncTest(" get all users /users", function() {
    expect(2);
    console.log("Started test get all users");
    //stop();
    $.getJSON('/users', function (data) {
        console.log("Returned users: "+data);

        // Always start test here
        equal(data.length > 0, true, "List of users should not be empty");

        console.log("Finished get all users");
        start();

    }).fail(function() {
        ok(false, "Received 500");
        // start here too in case ajax fails and
        // previous callback is not called
        start();
    });
});


asyncTest("User retrieve own information", function() {
    expect(2);
    var identifier = this.identifier;
    //stop();
    $.getJSON('/users/'+identifier, function (data) {
        console.log("Returned user data: ");
	console.dir(data);
        // Always start test here
        equal(data.identifier, identifier, "Identifier should match");

        start();

    }).fail(function() {
        ok(false, "Received 500");
        // start here too in case ajax fails and previous
        // callback is not called
        start();
    });
});



module( "Events", {
    // runs before each test
    setup: function() {
        var self = this;
        // Let's stop tests, otherwise tests may run while we login (ajax)
        stop();
        $.post('/users/login',
               { email: 'test@mit.edu', password: '123' },
               function(res) {
                   equal(res.status, 'ok', 'Login');
                   if(res.status == 'ok') {
		       console.dir(res);
                       self.identifier = res.identifier;

                       console.log("Logged in");
                       start();
                   }
               });
        // ajax calls
    },
    // runs after each test
    teardown: function() {
        $.getJSON('/users/logout', function (data) {
            // Assumes it returns okay (needs to check)
        });
    }
});

// Tests if a new event is made correctly.
asyncTest("New Event", function() {
    expect(7)

    var postObject = {
        event_type: "fun",
        event_time: new Date().getTime() + 10000,
        event_lat: 5.0,
        event_long: 5.0,
        event_loc_name: "locname",
    }
    $.post('/events/new', postObject, function (res) {
        var event_id = res.event_id;

        // Runs get events AFTER create
        $.getJSON('/events/'+event_id, function(res) {
            var first = res;

            notEqual(first, undefined, "first is undefined!");

            equal(first.type, "fun", "type");
            equal(first.timestamp, postObject.event_time,
                  "timestamp");
            equal(first.latitude, postObject.event_lat,
                  "latitude");
            equal(first.longitude, postObject.event_long,
                  "longitude");
            equal(first.location_name, "locname",
                  "location name");

            start();
        });

    }).fail(function() {
        ok(false, "500 status");
        // We need to tell the tests to run here too in
        // case it doesn't run on inside ajax call
        start();
    });
});

// Tests patching a new event.
asyncTest("Patch Event", function() {
    expect(6)

    var postObject = {
        event_type: "fun",
        event_time: new Date().getTime() + 10000,
        event_lat: 5.0,
        event_long: 5.0,
        event_loc_name: "locname",
    }

    $.post('/events/new', postObject, function (res) {
      var url = '/events/'+res.event_id;

      var patchObject = {
        event_type: "not fun",
        event_time: 123,
        event_lat: 8.0,
        event_long: 8.0,
      }

      $.ajax({
        url: url,
        type: 'PATCH',
        data: patchObject,
        success: function(res) {
          $.getJSON(url, function(res) {
              var first = res;

              notEqual(first, undefined, "first is undefined!");

              equal(first.type, "not fun", "type");
              equal(first.timestamp, patchObject.event_time,
                    "timestamp");
              equal(first.latitude, patchObject.event_lat,
                    "latitude");
              equal(first.longitude, patchObject.event_long,
                    "longitude");

          });
        },
        error: function(error) { console.log(error); }
      })
      .always(function() {
        start();
      });
    }).fail(function() {
        ok(false, "500 status");
        // We need to tell the tests to run here too in
        // case it doesn't run on inside ajax call
        start();
    });
});


// Tests patching a new event's group.
asyncTest("Patch Event Group", function() {
    expect(2)

    var postObject = {
        event_type: "fun",
        event_time: new Date().getTime() + 10000,
        event_lat: 5.0,
        event_long: 5.0,
        event_loc_name: "locname",
    }

    $.post('/events/new', postObject, function (res) {
      var url = '/events/'+res.event_id;

      var patchObject = {
        new_attendee: "5447208b02d84fd54e35c11e"
      }

      $.ajax({
        url: url + '/group',
        type: 'PATCH',
        data: patchObject,
        success: function(res) {
          $.getJSON(url, function(res) {
              equal(res.group[0], patchObject.new_attendee, "In group");
          });
        },
        error: function(error) { console.log(error); }
      })
      .always(function() {
        start();
      });
    }).fail(function() {
        ok(false, "500 status");
        // We need to tell the tests to run here too in
        // case it doesn't run on inside ajax call
        start();
    });
});


// Tests deleting a new event.
asyncTest("Delete Event", function() {
    expect(1)

    var postObject = {
        event_type: "fun",
        event_time: new Date().getTime() + 10000,
        event_lat: 5.0,
        event_long: 5.0,
        event_loc_name: "locname",
    }

    $.post('/events/new', postObject, function (res) {
        var deleteURL = '/events/'+res.event_id;
        $.ajax({
          url: deleteURL,
          type: 'DELETE',
          success: function(res) {
            $.getJSON(deleteURL, function(res) {
                equals(res, null, 'event is deleted');

                start();
            });
          },
          error: function(error) { console.log(error); }
        })
        .always(function() {
          start();
        });

    }).fail(function() {
        ok(false, "500 status");
        // We need to tell the tests to run here too in
        // case it doesn't run on inside ajax call
        start();
    });
});
