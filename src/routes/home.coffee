module.exports = (routes) ->
	routes.home = (req, res) ->
		res.render "index"
	routes.register = (req, res) ->
		res.render "register"