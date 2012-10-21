express = require "express"
MongoStore = (require "connect-mongo") express
path = require "path"
config = require "./config"
db = require "./db"

app = express()
app.set "views", path.join __dirname, "..", "views"
app.set "view engine", "jade"

app.use express.cookieParser()
app.use express.session
	secret: config.session.secret
	cookie:
		maxAge: config.session.maxAge
	store: new MongoStore
		mongoose_connection: db

app.use app.router
app.use express.errorHandler showStack: true, dumpExceptions: true

###
app.configure(function(){

  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});
###

routes = require "./routes"

app.get "/", routes.home
app.get config.runkeeper.auth.redirectUri, routes.auth
app.get "/register", routes.register
app.post "/register", routes.registerSubmit

app.listen process.env.PORT or 1234
