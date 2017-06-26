#!/bin/bash
#
# Eric Hartman (ech6581@rit.edu)
# CSCI-620 Introduction to Big Data
#
# habitual_offenders.sh
#   A script to scrape the public facing website of the Florida Department of Law Enforcement
#   to extract a complete list of currently registered habitual offenders living in the
#   city of Miami, FL.
#
#   Although this scripy may run successfully in Linux or Unix-like environments, the script
#   was developed and tested only on macos 10.12.5 Terminal window.
#

# Storage location for scraped pages...
PAGE_DIRECTORY="./www"

# Google Geocoding API Key
APIKEY="AIzaSyAPi2ZJtMrtQPCR5RQ27DauSOdMQlpfNck"

# Create PAGE_DIRECTORY if does not exist
if [ ! -d $PAGE_DIRECTORY ]
then
	echo "Creating $PAGE_DIRECTORY for artifacts..."
	mkdir $PAGE_DIRECTORY
fi

echo "Script to scrape registered habitual offenders from Miami Florida"

# Perform the initial search query to obtain a session key
INITIAL_PAGE="$PAGE_DIRECTORY/hinitial.html"
curl --cookie cookies.txt --cookie-jar newcookies.txt http://www.fdle.state.fl.us/coflyer/home.asp > $INITIAL_PAGE 2>&1

# Initialize our page counter
PAGE=1

# Initialize some other variables...
PAGELIMIT=2
CRIMEDATA="$PAGE_DIRECTORY/habitualoffenders.csv"

# Write out the header for our scraped data set...
echo "LASTNAME, FIRSTNAME, ADDRESS1, CITY, STATE, ZIP, LATITUDE, LONGITUDE" > $CRIMEDATA

# Search for first page is different than subsequent pages...
FORMDATA="cmd=Search&addChecks=&remChecks=&dhtmlType=ie&fname=&lname=&region=&county=Miami-Dade&city=Miami&zip=&address=&imgSubmit.y=15&SelectChks=0"

# Process all pages (1383 persons divided by 10 per page = 138 pages)
while [ $PAGE -lt $PAGELIMIT ]
do
	# Special handling for subsequent pages after the first...
	if [ $PAGE -gt 1 ]
	then
		# Use only page form element for subsequent page searches...
		FORMDATA="cmd=Page&addChecks=&remChecks=&dhtmlType=ie&selPage=$PAGE&PageNumber=$PAGE&PageSource=0&fname=&lname=&region=&county=Miami-Dade&city=Miami&zip=&address=&SelectChks=0"
	fi

	# Construct the page directory path
	PAGE_DIRECTORY_PATH="$PAGE_DIRECTORY/hpage_$PAGE.html"
	ONE_LINE_PATH="$PAGE_DIRECTORY/hone_line.$PAGE"
	ONE_LINE_PATH2="$PAGE_DIRECTORY/hone_line_stage2.$PAGE"
	TOTALRESULTSTEMP="$PAGE_DIRECTORY/totalresultstemp.$PAGE"
	LATITUDEPATH="$PAGE_DIRECTORY/latitude.out"
	LONGITUDEPATH="$PAGE_DIRECTORY/longitude.out"

	# Send request to retrieve a page of results...
	curl --data "$FORMDATA" --cookie newcookies.txt http://www.fdle.state.fl.us/coflyer/default.asp > $PAGE_DIRECTORY_PATH 2>&1

	# Process the page...
	echo "Processing page $PAGE."
	# Convert page into a single line...
	echo $(cat $PAGE_DIRECTORY_PATH) | iconv -f iso-8859-1 -t utf-8 > $ONE_LINE_PATH
	# Split line by "showGoogleMap("
	cat $ONE_LINE_PATH | LC_CTYPE=C sed -e $'s/<tr id=/<tr id=\\\n/g' | sed -e 's///g'  > $ONE_LINE_PATH2

	# Additional processing for first page...
	if [ $PAGE -eq 1 ]
	then
		# The initial page of results contains a drop down list for selecting all available pages.
		# We will parse the initial page to extract the LAST selectable page and use it as our
		# page limit.

		cat $ONE_LINE_PATH2 | awk -F"select" '{ print $3 }' | awk -F'<\/' '{ print $1 }' | sed -e $'s/<option value/\\\n<option value/g' > $TOTALRESULTSTEMP
		PAGELIMIT=`cat $TOTALRESULTSTEMP | awk -F'>' '{ print $2 }' | sort -n | tail -n -1`
		#echo "pagelimit = $PAGELIMIT"
	fi

	LINECOUNT=0
	while IFS='' read -r line
	do
		# Increment our line counter...
	 	LINECOUNT=`expr $LINECOUNT + 1`

		#echo "Processing line $LINECOUNT"
		if [ $LINECOUNT -eq 1 ]
		then
			# Skip the header line....
			continue
		fi

		# Extract lastname, firstname
		#echo $line

		LASTNAME=`echo $line | awk -F'</a>' '{ print $1 }' | awk -F"_flyer\'>" '{ print $2 }' | awk -F',' '{ print $1 }'`
		FIRSTNAME=`echo $line | awk -F'</a>' '{ print $1 }' | awk -F"_flyer\'>" '{ print $2 }' | awk -F',' '{ print $2 }'`
		ADDRESS1=`echo $line | awk -F'</a>' '{ print $3 }' | awk -F'<br>' '{ print $1 }' | awk -F'>' '{ print $3 }'`
		CITY=`echo $line | awk -F'</a>' '{ print $3 }' | awk -F'<br>' '{ print $2 }'`

		ADDRESS3=`echo $line | awk -F'</a>' '{ print $3 }' | awk -F'<br>' '{ print $3 }' | awk -F'&' '{ print $1 }'`
		STATE=`echo $ADDRESS3 | awk '{ print $1 }'`
		ZIP=`echo $ADDRESS3 | awk '{ print $2 }'`

		# Build up the URL parameters to submit the address to
		# Google Maps API for Geocoding of address to Latitude and Longitude
		# https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=AIzaSyAPi2ZJtMrtQPCR5RQ27DauSOdMQlpfNck
		RAWADDRESS="$ADDRESS1, $CITY, $STATE, $ZIP"
		ADDRESS=`echo $RAWADDRESS | sed -E 's/[[:space:]]/\+/g'`
		GEOCODINGURL="https://maps.googleapis.com/maps/api/geocode/json?address=$ADDRESS&key=$APIKEY"
		GEOCODINGPATH="$PAGE_DIRECTORY/geocoding.$PAGE.$LINECOUNT"
		curl --cookie newcookies.txt $GEOCODINGURL > $GEOCODINGPATH 2>&1

		# Parse out the latitude and longitude from JSON result set
		echo $(cat $GEOCODINGPATH) | sed -e $'s/location/\\\nlocation/g' | head -n 2 | tail -n 1 | awk -F':' '{ print $3 }' | awk -F',' '{ print $1 }' > $LATITUDEPATH
		echo $(cat $GEOCODINGPATH) | sed -e $'s/location/\\\nlocation/g' | head -n 2 | tail -n 1 | awk -F':' '{ print $4 }' | awk -F'}' '{ print $1 }' > $LONGITUDEPATH

		LATITUDE=`cat $LATITUDEPATH`
		LONGITUDE=`cat $LONGITUDEPATH`

		echo "$LASTNAME, $FIRSTNAME, $ADDRESS1, $CITY, $STATE, $ZIP, $LATITUDE, $LONGITUDE"
		echo "$LASTNAME, $FIRSTNAME, $ADDRESS1, $CITY, $STATE, $ZIP, $LATITUDE, $LONGITUDE" >> $CRIMEDATA
	done < $ONE_LINE_PATH2

	# Increment our page counter
	PAGE=`expr $PAGE + 1`
done

echo "Done processing, look at $CRIMEDATA for csv results."
