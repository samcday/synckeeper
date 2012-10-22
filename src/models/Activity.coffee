{Schema} = mongoose = require "mongoose"

ActivitySchema = module.exports = new Schema
	user:
		type: Schema.ObjectId
		ref: "User"
		required: true
		index: true
	runkeeperId:
		type: Number
		required: true
		index: true
	status:
		type: String
		required: true
	failReason:
		type: String
	type:
		type: String
		required: true
	

ActivitySchema.statics.findByRunkeeperId = (runkeeperId, cb) ->
	this.findOne { runkeeperId: runkeeperId }, cb
