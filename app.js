// General libraries used
var express      = require('express'),
    path         = require('path'),
    favicon      = require('serve-favicon'),
    logger       = require('morgan'),
    cookieParser = require('cookie-parser'),
    bodyParser   = require('body-parser'),
    session      = require('express-session'),
    helpers      = require('express-helpers');

// socket.io
var io = require('socket.io')(require('http').Server(express()));

// Routes
var index  = require("./routes/index");

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
app.use('/', index);

// Catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

// Development error handler
// Will print stacktrace
if (app.get('env') === 'development') {
  app.use(function(err, req, res, next) {
    res.status(err.status || 500);
      res.json(err);
      res.end();
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
