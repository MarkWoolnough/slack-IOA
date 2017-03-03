# slack-IOA
Repository for IBM Operations Analytics integration to Slack

This repository contains materials to:

a)  create the IOA app for Slack that contains the /ioa slash command

b)  create the SendtoSlack right hand click tool for the Omnibus Active Event List (AEL) in IBM Dash

Overview:

You will configure a Slack App.  You will then install a node instance on the IBM Operations Analytics Log Analysis server.  You will configure the node instance with this repository and configure a script to collect data for saved search definitions via an API leveraging the sample scenarios from Log Analysis.  Your node instance will accept incoming requests from Slack with the oauth authentication method used by Slack.  You may need to install something like ngrok (https://ngrok.com) to accept requests in your IOA software environment.  In addition, you can configure a tool to send an anomaly event to slack from Predictive Insights as part of the improved workflow experience we offer using Slack.

Suggested Steps (not yet tested!):

1.  Download the package as a zip file to your IBM Operations Analytics Log Analysis server or go to step 2 to install directly on your server from npm.

2.  Install node (https://nodejs.org/en/download/), npm (curl -L https://www.npmjs.com/install.sh | sh), git and optionally ngrok.  If you want to install slack-ioa from npm, run npm install slack-ioa.  Install the dependancies npm install express, npm install request, npm install body-parser.  If you need to install ngrok to make your server visible to slack requests: npm install ngrok.

3.  Edit the sample env file and add details of your own env.  Don't worry about the SLACK env variables for now:  you will populate these later, so set as temp values for now.  Export these variables to your shell.

4.  run your node instance (I run it like this:  node index.js > ioa.log 2> err.log.  You'll probably get some dependancy errors to install dependancies:  npm install express, request, etc.  When it runs clean, exit out (CTRL C).

5.  When you get node running with no errors, start your optional ngrok, add it to the /command and /oauth sections of your app as the ngrok address changes each time you run it (see steps 6 and 7):  ./ngrok http 4390 (this will start ngrok and display the https address you need to prefix to the /command and /oauth sections in the app (slash command and auth sections).

6.  Create your slack app:  Call it IOA, description: "Integration for IOA and Slack", generate the authentication tokens.  Note these down now and add them to your environment variables and env file for later reference (step 3).  

7.  Create your slash command in your app:  /ioa, https://c807dc87.ngrok.io/command (again, /command is the important bit here, add your ngrok or node address prefix, short description:  "Launch IOA Apps", usage hint "[la_dashboard|la_search] [name]"

8.  Send your app to your slack team:  https://api.slack.com/docs/slack-button.  I authorise the #general channel for my slack team.  Any problems at this point, check your env variables, oauth stuff and ensure it matches what you are configuring in the slack app.  If there are any changes, restart ngrok, add the new address to the oauth and slash command section and try again.

9.  If you want to add the right hand click tool, create a webhook [your slack team link]/apps/new/A0F7XDUAZ-incoming-webhooks] in Slack, give it a name "pi-anomaly" and assign a channel (#general).  Make a note of the webhook url.  Then, go into your Dash install, configure a new tool called SendtoSlack as a script and add the javascript text in the SendtoSlack document enclosed.  Change the server name and port as necessary and your generated webhook link so it works with your installation.
