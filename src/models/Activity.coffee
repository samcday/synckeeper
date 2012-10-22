{Schema} = mongoose = require "mongoose"

ActivitySchema = module.exports = new Schema
	user:
		type: Schema.ObjectId
		required: true
		index: true
	activityId:
		type: Number
		required: true
		index: true
	type:
		type: String
