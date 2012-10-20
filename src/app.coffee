express = require "express"
path = require "path"

app = express()
app.set "views", path.join __dirname, "..", "views"
app.set "view engine", "jade"

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

app.listen process.env.PORT or 1234
