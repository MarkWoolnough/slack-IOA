#===========================================================================

# Licensed Materials - Property of IBM

# 5725-K26

# (C) Copyright IBM Corp. 2013 All Rights Reserved.

# US Government Users Restricted Rights - Use, duplication or 
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#===========================================================================

if ( @ARGV != 5 )
{
  print "Number of arguments: " . scalar @ARGV . "\n";
  print "USAGE:  list.pl IPADDRESS PORT USERID PASSWORD HOMEDIR\n";
  exit 1;
}
else
{
  print "No arguments!\n";
}# count args

#--------------------------------------------------------------
# read command line parameters
#--------------------------------------------------------------
$IPADDRESS=$ARGV[0];
$PORT=$ARGV[1];
$USERID=$ARGV[2];
$PASSWORD=$ARGV[3];
$HOMEDIR=$ARGV[4];

#print "IPADDRESS:".$IPADDRESS."\n";;
#print "USERID:".$USERID."\n";
#print "PASSWPRD:".$PASSWORD."\n";
#print "HOMEDIR:".$HOMEDIR."\n";
#print "PORT:".$PORT."\n";

#----------------------------------------------------------
# Quick Search input definition
# Name
# Tag
# searchString
# starttime
# endtime
# logsources
#----------------------------------------------------------

#print "--------------------------\n";
#print "reading $ARGV[5] file \n";

#print "Name:".$Name."\n";
#print "Tag:".$Tag."\n";
#print "searchString:".$searchString."\n";
#print "starttime".$starttime."\n";
#print "endtime".$endtime."\n";
#print "datasources".$logsources."\n";

my $command = "python ".$HOMEDIR."/lib/python/admin.py ";
$command = $command." "."https://".$IPADDRESS.":".$PORT."/Unity/SearchPatterns GET ".$USERID." ".$PASSWORD." "."NONE";

@output = qx($command);
#print @output;
foreach my $i (@output)
{
   #print $i;
   if ($i =~ /\"name\":\"$Name\"/)
   {
         print "Quick Search with name $Name already exists\n";
         exit;
   }
}

#----------------------------------------------
# check if quick searches were created
#----------------------------------------------
my $command = "python ".$HOMEDIR."/lib/python/admin.py ";
$command = $command." "."https://".$IPADDRESS.":".$PORT."/Unity/SearchPatterns GET ".$USERID." ".$PASSWORD." "."NONE";

$output = qx($command);
#print $output;
my @records = split /, /, $output;

my $search_name;
my $search_pattern;
my $start;
my $dataSources;
my $end;
my $type;
my $period;
my $granularity;

foreach my $i (@records)
{
#   print $i,"\n";
   my @fields = split /\,\"/, $i;
#   print "$fields[2],$fields[3],$fields[5],$fields[8],$fields[10],$fields[11],$fields[12],$fields[15],\n";
   my $search_pattern, $start, $end, $datasource, $type, $period, $granularity;
   foreach my $field (@fields)
   {
#search_pattern_string":"J2C*",time_filter_start_time":"",search_index":"[{\"type\":\"tag\",\"name\":\"\\\/cloud provider application\\\/was\"}]",time_filter_end_time":"",time_filter_type":"relative",name":"wasLastYearJ2C",time_filter_period":1,time_filter_granularity":"year"}]
        # search_pattern_string":"J2C*
	if ($field =~ /name":"(.*)/){
		# set the search_pattern variable.
		$search_name = $1;
		# remove trailing "
		$search_name =~ s/"$//;
		# get rid of pesky \'s
		$search_name =~ s/\\//g;
#		print "search_name: $search_name \n";
	}
	if ($field =~ /search_pattern_string":"(.*)/){
		# set the search_pattern variable.
		$search_pattern = $1;
		# remove trailing "
		$search_pattern =~ s/"$//;
		# get rid of pesky \'s
		$search_pattern =~ s/\\//g;
		$search_pattern =~ s/ /%20/g;
		$search_pattern = "&queryString=$search_pattern\&dojo.preventCache=1379349240804&";
#		print "search_pattern: $search_pattern \n";
	}
	if ($field =~ /time_filter_start_time":"(.*)/){
		# set the search_pattern variable.
		$start = $1;
		# remove trailing "
		$start =~ s/"$//;
		# get rid of pesky \'s
		$start =~ s/\\//g;
		$start =~ s/ /%20/g;
		$start = "\"startTime\":\"$start:00\"";
#		print "start: $start \n";
	}
	# This is quite complex
	# Need to list the data sources separated by },{
	# check each to see whether its saved as a group (look for the word tag)
	# or a data source
	# Then, build the dataSources json based on what
	# you find above
	# [{"type":"tag","name":"/cloud provider application/was"},{"type":"tag","name":"/cloud provider application/db2"}]
	if ($field =~ /search_index":"(.*)/){
		# set the search_pattern variable.
		$datasource = $1;
		# remove trailing "
		$datasource =~ s/"$//;
		# get rid of pesky \'s
		$datasource =~ s/\\//g;
		$datasource =~ s/ /%20/g;
		my @sources = split /},{/, $datasource;	
		my $ctr=0;
		$dataSources="";
		foreach my $d (@sources) {
			if ($ctr >= 1) {
				$dataSources=$dataSources."},{";
			}
			if ($d =~ /tag","name":"(.*)/) {
				$dataSources=$dataSources."\"type\":\"group\",\"name\":\"".$1;
			} 
			# datasource: [{"type":"logSource","name":"/oracle"}]
			if ($d =~ /logSource","name":"(.*)/) {
				$dataSources=$dataSources."\"type\":\"datasource\",\"name\":\"".$1;
			}
			$ctr++;
		}
		$dataSources = "dataSources=[{".$dataSources;
#		print "dataSources: $dataSources \n";
	}
	if ($field =~ /time_filter_end_time":"(.*)/){
		# set the search_pattern variable.
		$end = $1;
		# remove trailing "
		$end =~ s/"$//;
		# get rid of pesky \'s
		$end =~ s/\\//g;
		$end =~ s/ /%20/g;
		$end = "\"endTime\":\"$end:00\"}";
#		print "end: $end \n";
	}
	if ($field =~ /time_filter_type":"(.*)/){
		# set the search_pattern variable.
		$type = $1;
		# remove trailing "
		$type =~ s/"$//;
		# get rid of pesky \'s
		$type =~ s/\\//g;
		$type = "\"type\":\"$type\"";
#		print "type: $type \n";
	}
	if ($field =~ /time_filter_period":(.*)/){
		# set the search_pattern variable.
		$period = $1;
		# remove trailing "
		$period =~ s/"$//;
		# get rid of pesky \'s
		$period =~ s/\\//g;
		$period = "\"lastnum\":$period";
#		print "period: $period \n";
	}
	if ($field =~ /time_filter_granularity":(.*)/){
		# set the search_pattern variable.
		$granularity = $1;
		# remove trailing "
		$granularity =~ s/"$//;
		# get rid of pesky \'s
		$granularity =~ s/\\//g;
		# remove trailing ]
		$granularity =~ s/\]//g;
		$granularity = "\"granularity\":$granularity";
#		print "granularity: $granularity \n";
	}
   }
   my $restCall;

   # now print the rest string
   if ($type =~ /absolute/) {
	$restcall = "name:".$search_name."	timefilters={".$type.",".$start.",".$end.$search_pattern.$dataSources."\n";
   } else {
	$restcall = "name:".$search_name."	timefilters={".$type.",".$period.",".$granularity.$search_pattern.$dataSources."\n";
   }
   print $restcall;
}
