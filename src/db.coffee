mongoose = require "mongoose"
config = require "./config"

module.exports = db = mongoose.createConnection config.mongo.uri()

db.model "User", require "./models/User"