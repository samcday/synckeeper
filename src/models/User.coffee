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
	profile:
		lastUpdated:
			type: Date
		name:
			type: String
		pic:
			type: String
	strava:
		token:
			type: String
		athleteId:
			type: Number

UserSchema.statics.findByUserId = (userId, cb) ->
	this.findOne { userId: userId }, cb

UserSchema.methods.updateProfile = (profile, cb) ->
	this.profile.lastUpdated = new Date()
	this.profile.name = profile.name
	this.profile.pic = profile.normal_picture
	this.save cb