{get, post} = request = require "request"
config = require "./config"

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
	rkGet accessToken, "/user", "User", cb

exports.profile = (accessToken, cb) ->
	rkGet accessToken, "/profile", "Profile", cb

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
