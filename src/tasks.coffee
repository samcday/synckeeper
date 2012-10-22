_ = require "underscore"
ironmq = require "ironmq"
{ironmq: {token, project}} = config = require "./config"

taskHandlers = 
	checkActivityFeed: require "./tasks/checkActivityFeed"

project = ironmq(token).projects(project)
queues = 
	activityFeed: project.queues "activityFeed"

class QueueProcessor
	constructor: (@queueName, @queue, @handler) ->
		@_read()
	_read: =>
		self = @
		@queue.get (err, msgs) ->
			return process.nextTick self._read if err
			msg = msgs.pop()
			return process.nextTick self._read unless msg
			try
				data = JSON.parse msg.body
				cb = (del) ->
					process.nextTick self._read
					msg.del() if del
				self.handler (self._createJobObj data, cb)
			catch e
				return process.nextTick self._read
	_createJobObj: (data, doneCb) =>
		self = @
		requeued = false
		return {
			data: data
			done: ->
				doneCb true
			error: (err) ->
				# TODO: log me properly?
				console.error err
				doneCb false
			requeue: (in) ->
				return if requeued or data.retries > 3
				requeued = true
				exports.queue(self.queueName)
					.delay(in)
					.body(data)
					.schedule ->
						doneCb true
		}

exports.startProcessingQueues = ->
	new QueueProcessor "activityFeed", queues.activityFeed, taskHandlers.checkActivityFeed

exports.queue = (jobName) ->
	queue = queues[jobName]
	throw new Error("Invalid jobname #{jobName}") unless queue
	opts = {}
	body = ""
	o = 
		body: (_body) -> body = if "object" is typeof _body then (JSON.stringify _body) else _body
		delay: (delay) -> opts.delay = delay
		schedule: (cb) -> queue.put body, opts, if cb then cb else (->)
