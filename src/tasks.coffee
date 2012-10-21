ironmq = require "ironmq"
{ironmq: {token, project}} = config = require "./config"

taskHandlers = 
	checkActivityFeed: require "./tasks/checkActivityFeed"

project = ironmq(token).projects(project)
queues = 
	activityFeed: project.queues "activityFeed"

class QueueReader
	constructor: (@queue, @handler) ->
		@_read()
	_read: =>
		self = @
		@queue.get (err, msgs) ->
			return process.nextTick self._read if err
			msg = msgs.pop()
			return process.nextTick self._read unless msg
			try
				data = JSON.parse msg.body
				self.handler data, ->
					msg.del ->
						return process.nextTick self._read
			catch e
				return process.nextTick self._read

new QueueReader queues.activityFeed, taskHandlers.checkActivityFeed

exports.queueCheckActivityFeed = (user) ->
	queues.activityFeed.put (JSON.stringify { user: user }), {}, ->
		console.log arguments


# exports.queueCheckActivityFeed 123