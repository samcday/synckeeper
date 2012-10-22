{get, post} = request = require "request"
config = require "./config"
util = require "./util"

exports.accessToken = (code, cb) ->
	reqOpts = 
		form:
			grant_type: "authorization_code"
			code: code
			client_id: config.runkeeper.clientId
			client_secret: config.runkeeper.clientSecret
			redirect_uri: config.runkeeper.buildRedirectUrl()
	post config.runkeeper.auth.endpoints.accessToken, reqOpts, (err, res, body) ->
		return cb err if err
		result = JSON.parse body
		return cb result.error if result.error
		cb null, result.access_token

exports.user = (accessToken, cb) ->
	rkGet(accessToken)
		.resource("/user")
		.type("User")
		.go cb

exports.profile = (accessToken, cb) ->
	rkGet(accessToken)
		.resource("/profile")
		.type("Profile")
		.go cb

exports.fitnessActivities = (accessToken, since, cb) ->
	if "function" is typeof since
		cb = since
		since = null

	req = rkGet(accessToken)
		.resource("/fitnessActivities")
		.type("FitnessActivityFeed")

	req.header "If-Modified-Since", (util.httpDate since) if since

	req.go (err, result, resp) ->
		return cb err if err
		cb null, if resp.statusCode isnt 304 then result else []

exports.activity = (accessToken, activityId, cb) ->
	rkGet(accessToken)
		.resource("/fitnessActivities/#{activityId}")
		.type("FitnessActivity")
		.go cb

###
rkGet = (accessToken, uri, type, cb) ->
	reqOpts = 
		headers:
			Authorization: "Bearer #{accessToken}"
			Accept: "application/vnd.com.runkeeper.#{type}+json"
	get config.runkeeper.endpoint + uri, reqOpts, (err, res, body) ->
		return cb err if err
		result = JSON.parse body
		cb result.error if result.error
		cb null, result
###

rkGet = (accessToken) ->
	reqOpts =
		headers:
			Authorization: "Bearer #{accessToken}"
	resource = "/"

	o = {}
	o.resource = (_resource) ->
		resource = _resource
		return o
	o.type = (type) -> 
		reqOpts.headers.Accept = "application/vnd.com.runkeeper.#{type}+json"
		return o
	o.header = (name, value) ->
		reqOpts.headers[name] = value
		return o
	o.go = (cb) ->
		get config.runkeeper.endpoint + resource, reqOpts, (err, resp, body) ->
			console.log reqOpts
			return cb err if err
			result = JSON.parse body if body
			cb result.error if result?.error
			cb null, result, resp
	return o