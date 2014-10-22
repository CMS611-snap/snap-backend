// General libraries used
var express      = require('express'),
    path         = require('path'),
    favicon      = require('serve-favicon'),
    logger       = require('morgan'),
    cookieParser = require('cookie-parser'),
    bodyParser   = require('body-parser'),
    session      = require('express-session'),
    helpers      = require('express-helpers');

// Database declaration
var mongo    = require('mongodb'),
    mongoose = require('mongoose');

// Put into mongoose
require('./models/user');
require('./models/event');

// Connect the mongoose wrapper to the database
// Choose OPENSHIFT connection path if it is defined.
var connection_string = 'localhost/serendipity';

if (process.env.OPENSHIFT_MONGODB_DB_PASSWORD) {
      connection_string = process.env.OPENSHIFT_MONGODB_DB_USERNAME + ':' +
	        process.env.OPENSHIFT_MONGODB_DB_PASSWORD + '@' +
	        process.env.OPENSHIFT_MONGODB_DB_HOST + ':' +
	        process.env.OPENSHIFT_MONGODB_DB_PORT + '/' +
	        process.env.OPENSHIFT_APP_NAME;
    }
mongoose.connect(connection_string);

var db = mongoose.connection;

// Routes
var users  = require("./routes/users");
var events = require("./routes/events");

// App and express-helpers
var app = express();
helpers(app);

// View engine setup with ejs
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// Use cute favicon in /public
app.use(favicon(__dirname + '/public/favicon.ico'));

// Start dev the logger
app.use(logger('dev'));

// Use the Body and Cookie Parser
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());

// Session control
app.use(session({secret: 'secret sceret screet',
		 saveUninitialized: true,
		 resave: true
		}));

// Static serving of "public" directory
app.use(express.static(path.join(__dirname, 'public')));

// Give URL(s) for a file to use
// See "Routes" above for definitions of use files
app.use('/users', users);
app.use('/events', events);

// Catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

// Mongoose error handler
db.on('error', console.error.bind(console, 'connection error:'));

// Development error handler
// Will print stacktrace
if (app.get('env') === 'development') {
  app.use(function(err, req, res, next) {
    res.status(err.status || 500);
      res.json(err);
      res.end();
      // res.render('error', {
      // 	  message: err.message,
      // 	  error: err
      // });
  });
}

// Production error handler
// No stacktraces leaked to user
app.use(function(err, req, res, next) {
  res.status(err.status || 500);
    res.json(err);
    res.end();
    
});

var port = process.env.OPENSHIFT_NODEJS_PORT;
var ip = process.env.OPENSHIFT_NODEJS_IP;

app.listen(port || 8080, ip);


module.exports = app;

