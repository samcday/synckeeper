strava = require "../strava"
middleware = require "./middleware"

module.exports = (app) ->
	app.post "/strava/connect", middleware.getUser, (req, res, next) ->
		# TODO: form validation
		strava.login req.body.email, req.body.password, (err, token, id) ->
			if err
				return res.redirect "?stravaError=1"
			req.user.strava.token = token
			req.user.strava.athleteId = id
			req.user.save (err) ->
				return next err if err
				res.redirect ""