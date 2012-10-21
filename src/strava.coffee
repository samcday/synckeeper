{post} = request = require "request"
{strava: {endpoint}} = config = require "./config"

exports.login = (email, password, cb) ->
	reqOpts =
		form:
			email: email
			password: password
	post "#{endpoint}/authentication/login", reqOpts, (err, resp, body) ->
		return cb err if err
		result = JSON.parse body
		return cb result.error if result.error
		cb null, result.token, result.athlete.id
