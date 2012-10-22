###
This task will process a newly discovered Runkeeper activity. It will:
 * Load the activity data from /fitnessActivites/<id>
 * Populate the Activity document in our DB
 * Determine the timezone for the activity based on first geopoint geocoded with
   Yahoo Placefinder API.
 * Schedule a stravaUpload task if the User is connected to Strava.
###
async = require "async"
runkeeper = require "../runkeeper"
db = require "../db"

User = db.model "User"

module.exports = (job, cb) ->
	{activityId, user} = job

	async.parallel {
		user: (cb) -> User.findById user, cb
		activity: (cb) -> runkeeper.activity activityId, cb
	}, (err, {user, activity}) ->
		console.log user, activity