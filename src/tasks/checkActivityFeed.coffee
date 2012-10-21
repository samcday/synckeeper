# This task will check Runkeeper for new activites and schedule processActivity
# tasks for each new activity it finds. This task will schedule itself to 
# execute again in an hour when it completes.
module.exports = (job, cb) ->
	console.log "got job!", job
	cb()
