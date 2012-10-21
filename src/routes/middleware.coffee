db = require "../db"

User = db.model "User"

exports.getUser = (req, res, next) ->
	if req.session.user
		User.findById req.session.user, (err, user) ->
			return next err if err
			req.user = user
			next()
	else
		next()