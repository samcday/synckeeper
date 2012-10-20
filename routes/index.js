var querystring = require("querystring");
var request = require("../request");
var builder = require("xmlbuilder");
var moment = require("moment");
var async = require("async");
var jsdom = require("jsdom");
var path = require("path");
var fs = require("fs");

var iso8601NoMillis = "YYYY-MM-DDTHH:mm:ss\\Z";
var runkeeperDate = "ddd, D MMM YYYY HH:mm:ss";
var niceDate = "M/D/YY h:mm a";
/*
 * GET home page.
 */

function doLogin(req, cb) {
	console.log("opening login page");
	request.get({
		url: "https://www.strava.com/login",
		jar: req.jar
	}, function(err, request, body) {
		jsdom.env(body, [], function(err, win) {
			var doc = win.document;
			var authToken = doc.getElementsByName("authenticity_token")[0].getAttribute("value");

			process.nextTick(function() {
				sendLogin(req, authToken, cb);
			})
		});
	});
}

function sendLogin(req, authToken, cb) {
	console.log("sending login.");
	request.post({
		url: "https://www.strava.com/session",
		form: {
			email: req.app.settings.stravauser,
			password: req.app.settings.stravapass,
			authenticity_token: authToken
		},
		jar: req.jar
	}, function(error, resp, body) {
		cb();
	});
}

function uploadFile(req, file, cb) {
	console.log("opening upload page.");
	request.get({
		url: "http://app.strava.com/upload/select",
		jar: req.jar
	}, function(err, req, body) {
		jsdom.env(body, [], function(err, win) {
			var doc = win.document;
			var authToken = doc.getElementsByName("authenticity_token")[0].getAttribute("value");

			console.log("got upload authToken:", authToken);
			process.nextTick(function() {
				doUpload(req, authToken, file, cb);
			})
		});
	});
}

function doUpload(req, authToken, file, cb) {
	var data = fs.readFileSync(file);

	var post = request.post({
		url: "http://app.strava.com/upload/file",
		headers: {
            'content-type' : 'multipart/form-data'
        },
        multipart: [
        	{
        		'Content-Disposition' : 'form-data; name="file"; filename="file.gpx"',
        		'Content-Type' : 'application/octet-stream',
        		body: data
        	}
        ],
        jar: req.jar
	}, function(err, req, body) {
		cb(err);
	})
}

function exportActivities(req, uri, cb) {
	request.get({
		url: "http://api.runkeeper.com" + uri,
		headers: {
			accept: "application/vnd.com.runkeeper.FitnessActivityFeed+json",
			authorization: "Bearer " + req.cookies.rktoken
		}
	}, function(err, resp, body) {
		body = JSON.parse(body);

		var uris = body.items.map(function(item) {
			return item.uri;
		});

		async.forEachSeries(uris, exportActivity.bind(req), function(err) {
			if(err) {
				throw err;
			}

			if(body.next) {
				process.nextTick(function() {
					exportActivities(req, body.next, cb);
				});
			}
			else {
				cb();
			}
		});
	})
}

function exportActivity(uri, cb) {
	var activityId = parseInt(uri.replace("/fitnessActivities/", ""));
	var dir = path.join(this.session.dir, ""+activityId);
	console.log("Loading activity " + activityId);

	request.get({
		url: "http://api.runkeeper.com" + uri,
		headers: {
			accept: "application/vnd.com.runkeeper.FitnessActivity+json",
			authorization: "Bearer " + this.cookies.rktoken
		}
	}, function(err, resp, body) {
		body = JSON.parse(body);
		
		var path = body.path;

		var start = moment(body.start_time, runkeeperDate).utc();
		var doc = builder.create();
		var root = doc.begin("gpx", { version: "1.0", encoding: "UTF-8" });
		root.att("version", "1.1");
		root.att("creator", "RunKeeper - http://www.runkeeper.com");
		root.att("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
		root.att("xmlns", "http://www.topografix.com/GPX/1/1");
		root.att("xsi:schemaLocation", "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd");
		root.att("xml:gpxtpx", "http://www.garmin.com/xmlschemas/TrackPointExtension/v1");

		var trkseg = root.ele("trk")
				.ele("name")
					.dat(body.type + " - " + moment(start).add("h", 10).format(niceDate))
					.up()
				.ele("time")
					.txt(start.format(iso8601NoMillis))
					.up()
				.ele("trkseg");

		path.forEach(function(item) {
			trkseg.ele("trkpt")
				.att("lat", item.latitude.format(9))
				.att("lon", item.longitude.format(9))
				.ele("ele")
					.txt(item.altitude.round(1))
					.up()
				.ele("time")
					.txt(moment(start).add("s", item.timestamp).format(iso8601NoMillis))
		});

		fs.writeFile(dir, doc.toString(), cb);
	});
}

exports.index = function(req, res){
	var jar = request.jar();

	if(req.cookies.rktoken) {
		res.redirect("/export");
		return;
	}

	var params = querystring.stringify({
		client_id: req.app.settings.rkclientid,
		response_type: "code",
		redirect_uri: "http://" + req.headers.host + "/auth"
	});
	res.redirect("https://runkeeper.com/apps/authorize?" + params);

  // res.render('index', { title: 'Express' })
};

exports.export = function(req, res) {
	if(!req.cookies.rktoken) {
		res.redirect("/");
	}

	exportActivities(req, "/fitnessActivities", function() {
		res.send("Done! Now go import!");
	});
}

exports.auth = function(req, res) {
	console.log(req.query);
	request.post({
		url: "https://runkeeper.com/apps/token",
		form: {
			grant_type: "authorization_code",
			code: req.query.code,
			client_id: req.app.settings.rkclientid,
			client_secret: req.app.settings.rkclientsecret,
			redirect_uri: "http://" + req.headers.host + "/auth"
		}
	}, function(error, response, body) {
		body = JSON.parse(body);
		res.cookie("rktoken", body.access_token);
		res.redirect("/");
	});
};

exports.import = function(req, res) {
	doLogin(req, function() {
		var files = fs.readdirSync(req.session.dir).map(function(it) {
			return path.join(req.session.dir, it);
		});

		async.forEachSeries(files, function(file, cb) {
			console.log("uploading... " + file);
			uploadFile(req, file, function(err) {
				if(err) { throw err; }
				setTimeout(function() {
					console.log("uploaded " + file);
					fs.unlinkSync(file);
					cb(err);
				}, 10 * 1000);
			});
		}, function() {
			res.send("DONE!");
		});
	});
};
