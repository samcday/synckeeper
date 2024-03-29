_ = require "underscore"
url = require "url"

config = exports
mongo = config.mongo = {}
runkeeper = config.runkeeper = {}
strava = config.strava = {}
session = config.session = {}
ironmq = config.ironmq = {}

# General configuration goes here.
_.extend session,
	maxAge: null

_.extend runkeeper,
	clientId: process.env.RUNKEEPER_CLIENT_ID
	clientSecret: process.env.RUNKEEPER_CLIENT_SECRET
	endpoint: "https://api.runkeeper.com"
	auth:
		endpoints:
			auth: "https://runkeeper.com/apps/authorize"
			accessToken: "https://runkeeper.com/apps/token"
		redirectUri: "/auth"

_.extend strava,
	endpoint: "https://www.strava.com/api/v2"

_.extend ironmq, 
	hostname: "mq-aws-us-east-1.iron.io"
	port: 11300
	token: process.env.IRONMQ_TOKEN
	project: process.env.IRONMQ_PROJECT

# Env specific configuration goes here.
if process.env.NODE_ENV is "production"
	# TODO
	config.host = "todo"
	config.port = 80
	session.secret = ""
	_.extend mongo,
		host: "localhost"
		port: 27017
		db: "synckeeper"
		username: undefined
		password: undefined
else
	config.host = "localhost"
	config.port = 1234
	session.secret = "seekwet!"
	_.extend mongo,
		host: "localhost"
		port: 27017
		db: "synckeeper"
		username: undefined
		password: undefined

# Helper methods go here.
mongo.uri = ->
	auth = ""
	auth = "#{mongo.username}:#{mongo.password}@" if mongo.username and mongo.password
	return "mongodb://#{auth}#{mongo.host}:#{mongo.port}/#{mongo.db}"

runkeeper.buildAuthorizeUrl = ->
	parsed = url.parse runkeeper.auth.endpoints.auth, true
	parsed.query.client_id = runkeeper.clientId
	parsed.query.response_type = "code"
	parsed.query.redirect_uri = runkeeper.buildRedirectUrl()
	return url.format parsed
runkeeper.buildRedirectUrl = -> url.format
	protocol: "http"
	hostname: config.host
	port: config.port
	pathname: runkeeper.auth.redirectUri

ironmq.host = -> "#{ironmq.hostname}:#{ironmq.port}"