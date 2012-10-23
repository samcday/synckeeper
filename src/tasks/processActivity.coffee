###
This task will process a newly discovered Runkeeper activity. It will:
 * Load the activity data from /fitnessActivites/<id>
 * Populate the Activity document in our DB
 * Determine the timezone for the activity based on first geopoint geocoded with
   Yahoo Placefinder API.
 * Schedule a stravaUpload task.
###
async = require "async"
runkeeper = require "../runkeeper"
db = require "../db"
tasks = require "../tasks"

User = db.model "User"
Activity = db.model "Activity"

module.exports = (job, cb) ->
	{activityId} = job.data

	async.waterfall [
		(cb) -> Activity.findById(activityId).populate("user").exec cb
		(activity, cb) ->
			runkeeper.activity activity.user.accessToken, activity.runkeeperId, (err, rkActivity) ->
				return cb err if err?
				return cb null, {rkActivity: rkActivity, activity: activity}
	], (err, {activity, rkActivity}) ->
		return job.error err if err
		{user} = activity

		fail = (err) ->
			console.error "Couldn't process activity #{activityId}", err
			activity.status = "Error"
			return job.error err
			# TODO: end user readable reason?

		# TODO: what if activity doesn't exist anymores?
		return job.requeue 3600 if rkActivity.is_live
		# If the activity isn't live and the duration is empty then we give up.
		return job.done() unless rkActivity.duration

		