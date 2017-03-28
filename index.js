// Import express and request modules
var express = require('express');
var request = require('request');
var bodyParser = require('body-parser');

// Instantiates Express and assigns our app variable to it
var app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Port to listen
const PORT=4390;

// Read env vars
// Set then in the bash env:  reference the env file for these
var LA_IP = process.env.LA_IP;
var LA_PORT = process.env.LA_PORT;
var LA_USER = process.env.LA_USER;
var LA_PASSWORD = process.env.LA_PASSWORD;
var LA_HOME = process.env.LA_HOME;
var LA_HOST = process.env.LA_HOST;

// Lets start our server
app.listen(PORT, function () {
    //Callback triggered when server is successfully listening. Hurray!
    console.log("IOA app listening on port " + PORT);
});

// Auth

app.get('/oauth', function(req, res){
  if (!req.query.code) { // access denied
    res.send({"Error": "Looks like we're not getting code."});
    console.log("Looks like we're not getting code.");
    return;
  }
  var data = {form: {
      client_id: process.env.SLACK_CLIENT_ID,
      client_secret: process.env.SLACK_CLIENT_SECRET,
      code: req.query.code
  }};
  
  request.post('https://slack.com/api/oauth.access', data, function (error, response, body) {
    if (!error && response.statusCode == 200) {
      // Get an auth token
      let token = JSON.parse(body).access_token;
      // If the token is undefined, exit
      if (typeof token === "undefined") {
        res.send('Failed to get a token.  Check your environment.  Auth Failed!');
	return;
      }

      // Get the team domain name to redirect to the team URL after auth
      request.post('https://slack.com/api/team.info', {form: {token: token}}, function (error, response, body) {
        if (!error && response.statusCode == 200) {
          if(JSON.parse(body).error == 'missing_scope') {
            res.send('IOA has been added to your team!');
          } else {
            let team = JSON.parse(body).team.domain;
            res.redirect('http://' +team+ '.slack.com');
          }
        }
      });
    }
  })
});

app.post('/command', function(req, res) {
	parseQuery(req.body, res);
});

app.get('/', function(req, res) {
       res.send('IOA is working! Path Hit: ' + req.url);
	parseQuery(req.body, res);
});

function parseQuery(q, res) {
   if(q.token !== process.env.SLACK_VERIFICATION_TOKEN) {
    	// the request is NOT coming from Slack!
    	return;
   }
   if(q.text) {
	// Check the usage first
	console.log("TEXT is " + q.text);
	if ( ! /la_dashboard|la_search/.test(q.text)) {
		res.send('Incorrect Usage!  /ioa [la_dashboard|la_search] [name]');
                return;
	}
	if ( ! /\w+ \w+/.test(q.text)) {
		res.send('Incorrect Usage!  Need 2 argument values:  /ioa [la_dashboard|la_search] [name]');
                return;
	}
	// end of usage checks
	//
	// Is this an la_dashboard launch request?
	if ( /^la_dashboard/.test(q.text)) {
                var dash = q.text.match(/la_dashboard (.*)/)[1];
                var exec = require('child_process').exec;

		// CustomAppsUI API uses the app name in the file name.
		// User will be expecting name as it appears in Search Page.
		// Search page uses the name value property set in the app file
		// However! if it matches the value "Dynamic Dashboard for Unity", it uses
		// the app file name as the Dashboard name(!)
		// Bit confusing
		// First find builds app name from inside file and passes file name for API
		// Second uses the liternal value
//		exec('find  ' + LA_HOME + '/AppFramework/Apps/Dashboards -name *.app -exec head -5 {} \\; | egrep name | sed -e \'s/\"//g\' | awk -F\\: \'{print $2}\' | egrep -v \"Dynamic Dashboard for Unity" | sed -e \'s\/,//g\' | sed -e \'s/^ //g\' | sed -e \'s/ /%20/g\'', function callback(error, stdout, stderr) {
		exec('find  ' + LA_HOME + '/AppFramework/Apps/Dashboards -name *.app -print | awk -F\/ \'{print $NF}\' | sed -e \'s/.app//g\' | sed -e \'s/^ //g\' | sed -e \'s/ /%20/g\'', function callback(error, stdout, stderr) {
		if (error) {
               		res.send("Got an error running the list command from command line, check your env");
    			console.error(`exec error: ${error}`);
    			return;
  		}
		// split the output into lines array
		lines = stdout.toString().split('\n');
		// loop through the lines, get the fields,
		// search for a match
		var dashboards = "";
		lines.forEach(function(line) {
                	console.log("line: " + line);
			if (line.match(dash)) {
			    dashboards = dashboards + "Dashboard Name: " + line + ":  https://" + LA_HOST + ":" + LA_PORT + "/Unity/CustomAppsUI?name=" + line + "\n";
			}
		});
		if (dashboards === "") {
                    let data = {
                        response_type: 'ephemeral', // public to the channel
                        text: 'No Dashboards found that match your pattern ' + dash
                    };
                    res.send(data);
		} else {
                    let data = {
                        response_type: 'in_channel', // public to the channel
                        text: 'Found the following Dashboards for pattern ' + dash,
                        attachments:[
                        {
                                text: dashboards
                        }
                    ]};
                    res.send(data);
		}
                console.log("dashboards: " + dashboards);
                });
	}
	// Is this a request to launch a saved search?
	if ( /^la_search/.test(q.text)) {
		var search = q.text.match(/la_search (.*)/)[1];
		var exec = require('child_process').exec;

		console.log('perl ./list.pl ' + LA_IP + ' ' + LA_PORT + ' ' + LA_USER + ' ' + LA_PASSWORD + ' ' + LA_HOME);
		exec('perl ./list.pl ' + LA_IP + ' ' + LA_PORT + ' ' + LA_USER + ' ' + LA_PASSWORD + ' ' + LA_HOME, function callback(error, stdout, stderr) {
		if (error) {
               		res.send("Got an error running the list command from command line, check your env");
    			console.error(`exec error: ${error}`);
    			return;
  		}
		// split the output into lines array
		lines = stdout.toString().split('\n');
		// loop through the lines, get the fields,
		// search for a match
		var urls = "";
		lines.forEach(function(line) {
			var fields = line.split("\t");
			if (fields[0].match(search)) {
				console.log("found a match: " + fields[1]);
				urls = urls + "Search Name: " + fields[0] + ":  https://" + LA_HOST + ":" + LA_PORT + "/Unity/SearchUI?" + fields[1] + "\n";
			}
		});
		if (urls === "") {
		    let data = {
                        response_type: 'ephemeral', // public to the channel
                        text: 'No Saved Searches found that match your pattern ' + search
    		    };
                    res.send(data);
		} else {
		    let data = {
      			response_type: 'in_channel', // public to the channel
      			text: 'Found the following Saved searches for pattern ' + search,
      			attachments:[
      			{
        			text: urls
      			}
    		    ]};
                    res.send(data);
		}
		console.log("urls: " + urls);
   		});
	}
   }
}
