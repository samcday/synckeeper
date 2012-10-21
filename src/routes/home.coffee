runkeeper = require "../runkeeper"
config = require "../config"
db = require "../db"

User = db.model "User"

module.exports = (routes) ->
	routes.home = (req, res) ->
		# If we don't have a user then we need to auth.
		unless req.session.user
			res.locals.authUrl = "/auth"
			return res.render "welcome"
		res.send "You're signed in! YAY!"
	routes.auth = (req, res, next) ->
		# If we have an access token we should be attempting to register with it
		if req.session.accessToken
			return res.redirect "register"

		# If we don't have a token or a auth code, then it's time to send user 
		# to Runkeeper's login flow.
		unless req.query.code
			return res.redirect config.runkeeper.buildAuthorizeUrl()

		# Okay we have an auth code, let's try turning it into an access token.
		runkeeper.accessToken req.query.code, (err, token) ->
			# TODO: error handling.
			return next err if err

			# Success. Let's see if this user has already registered.
			runkeeper.user token, (err, user) ->
				# TODO: error handling.
				User.findByUserId user.userID, (err, user) ->
					# Welcome back buddy.
					if user
						req.session.user = user.id
						return res.redirect ""
					
					# It's a new guy. Take them to our register flow.
					req.session.accessToken = token
					res.redirect "register"

	routes.register = (req, res) ->
		console.log "weee"
		res.send "this is the register flow. #{req.session.accessToken}"