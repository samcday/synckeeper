###
This task checks the status of a Strava activity upload. Once Strava reports 
success, this task will update the Activity in our DB to reflect success. If 
Strava reports failure, this task will schedule a retry stravaUpload task, but
only if max retries hasn't been exceeded.
###