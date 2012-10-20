var temp = require("temp");
require("sugar");

/**
 * Module dependencies.
 */

var express = require('express')
  , routes = require('./routes');

var app = module.exports = express.createServer();

// Configuration

// Runkeeper api.
app.set("rkclientid", process.env.RK_CLIENT);
app.set("rkclientsecret", process.env.RK_SECRET);
app.set("stravauser", process.env.STRAVA_USER);
app.set("stravapass", process.env.STRAVA_PASS);

app.use(express.cookieParser());
var RedisStore = require('connect-redis')(express);
app.use(express.session({secret: "lolwut?", store: new RedisStore()}));

app.use(function(req, res, next) {
  if(!req.session.dir) {
    req.session.dir = temp.mkdirSync();
  }
  console.log("temp session dir is ", req.session.dir);
  next();
});

app.configure(function(){
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

app.configure('production', function(){
  app.use(express.errorHandler());
});

// Routes

app.get('/', routes.index);
app.get('/auth', routes.auth);
app.get('/export', routes.export);
app.get("/import", routes.import);

app.listen(3000, function(){
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
});
