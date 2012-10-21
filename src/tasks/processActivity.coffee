###
This task will process a newly discovered Runkeeper activity. It will:
 * Load the activity data from /fitnessActivites/<id>
 * Populate the Activity document in our DB
 * Determine the timezone for the activity based on first geopoint geocoded with
   Yahoo Placefinder API.
 * Schedule a stravaUpload task if the User is connected to Strava.
###