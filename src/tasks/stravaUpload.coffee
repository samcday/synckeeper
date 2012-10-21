###
This task will upload a recently processed Runkeeper activity to Strava. It does
this by building the payload and using Strava's upload endpoint in its v2 api.
Once the upload is completed successfully a checkStravaUpload task is scheduled.