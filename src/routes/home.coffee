_ = require "underscore"
runkeeper = require "../runkeeper"
config = require "../config"
db = require "../db"

middleware = require "./middleware"

User = db.model "User"

module.exports = (app) ->
	app.get "/", middleware.getUser, (req, res, next) ->
		# If we don't have a user then we need to auth.
		unless req.user
			res.locals.authUrl = "/auth"
			return res.render "welcome"

		res.locals.user = req.user
		res.locals.stravaError = req.query.stravaError
		res.locals.isStravaConnected = !!req.user.strava?.token
		res.locals.stravaConnectAction = "/strava/connect"

		res.render "dashboard"

	app.get config.runkeeper.auth.redirectUri, (req, res, next) ->
		# If we have an access token we should be attempting to register with it
		if req.session.register
			return res.redirect "register"

		# If we don't have a token or a auth code, then it's time to send user 
		# to Runkeeper's login flow.
		unless req.query.code
			return res.redirect config.runkeeper.buildAuthorizeUrl()

		# Okay we have an auth code, let's try turning it into an access token.
		runkeeper.accessToken req.query.code, (err, token) ->
			# TODO: error handling.
			return next err if err

			runkeeper.profile token, (err, rkProfile) ->
				# TODO: error handling.
				return next err if err				
				# Success. Let's see if this user has already registered.
				runkeeper.user token, (err, rkUser) ->
					# TODO: error handling.
					User.findByUserId rkUser.userID, (err, user) ->
						if user
							# Welcome back buddy.
							req.session.user = user.id

							# Let's go ahead and update the access token now.
							# It may not have changed since last time, but can't
							# hurt. No save() here, as updateProfile does.
							user.accessToken = token
							user.updateProfile rkProfile, ->
								return res.redirect ""

						# It's a new guy. Take them to our register flow.
						req.session.register =
							token: token
							user: rkUser
							profile: rkProfile
						res.redirect "register"

	app.get "/register", (req, res) ->
		data = req.session.register
		unless data
			return res.redirect ""

		res.locals.action = "/register"
		res.locals.profile =
			name: data.profile.name
			pic: data.profile.normal_picture

		res.render "register"

	app.post "/registerSubmit", (req, res, next) ->
		data = req.session.register
		unless data
			return res.redirect ""

		# TODO: profile stuff.
		newUser = new User
			userId: data.user.userID
			accessToken: data.token
			profile: data.profile
		newUser.save (err) ->
			# TODO: error handling. Validation errors too.
			return next err if err
			req.sesion.register = null
			req.session.user = newUser.id
			res.redirect ""


	app.get "/test", middleware.getUser, (req, res) ->
		runkeeper.fitnessActivities req.user.accessToken, (err, activities) ->
			res.json activities