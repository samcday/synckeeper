{Schema} = mongoose = require "mongoose"

UserSchema = module.exports = new Schema
	userId:
		type: Number
		required: true
		index:
			unique: true
	accessToken:
		type: String
		required: true

UserSchema.statics.findByUserId = (userId, cb) ->
	this.findOne { userId: userId }, cb