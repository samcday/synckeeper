moment = require "moment"

httpDateFormat = "ddd\\, DD MMM YYYY HH:mm:ss [GMT]"
exports.httpDate = (date) ->
	return moment(date).format httpDateFormat

#Sat, 29 Oct 1994 19:43:31 GMT