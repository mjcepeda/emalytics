#!/bin/bash
#
# Eric Hartman (ech6581@rit.edu)
# CSCI-620 Introduction to Big Data
#
# offenders.sh
#   A script to scrape the public facing website of the Florida Department of Law Enforcement
#   to extract a complete list of currently registered sex offenders living in the
#   city of Miami, FL.
#
#   Although this scripy may run successfully in Linux or Unix-like environments, the script
#   was developed and tested only on macos 10.12.5 Terminal window.
#

# Storage location for scraped pages...
PAGE_DIRECTORY="./www"

# Create PAGE_DIRECTORY if does not exist
if [ ! -d $PAGE_DIRECTORY ]
then
	echo "Creating $PAGE_DIRECTORY for artifacts..."
	mkdir $PAGE_DIRECTORY
fi

echo "Script to scrape registered sex offenders from Miami Florida"

# Perform the initial search query to obtain a session key
INITIAL_PAGE="$PAGE_DIRECTORY/initial.html"
curl --cookie cookies.txt --cookie-jar newcookies.txt http://offender.fdle.state.fl.us/offender/offenderSearchNav.do > $INITIAL_PAGE 2>&1

# Initialize our page counter
PAGE=1

# Initialize some other variables...
COMMASEPARATEDPERSONIDSALL=""
TOTALRESULTSCOUNT=0
PAGELIMIT=2
CRIMEDATA="$PAGE_DIRECTORY/sexoffenders.csv"

# Write out the header for our scraped data set...
echo "LASTNAME, FIRSTNAME, PERSONID, IMAGEID, SUBJECTYPE, ADDRESSLINE1, ADDRESSLINE2, CITY, STATE, ZIP, COUNTY, LATITUDE, LONGITUDE" > $CRIMEDATA

# Search for first page is different than subsequent pages...
FORMDATA="firstName=&includeAliases=on&lastName=&city=Miami&county=Miami-Dade&outOfFloridaCounty=&zip=&offenderType=3&lglStatus_1=1&lglStatus_6=6&lglStatus_7=7&lglStatus_8=8&lglStatus_9=9&stateStatus=1&link=doSearch&commaSeparatedOffenderStatus=1%2C6%2C7%2C8%2C9&commaSeparatedPersonIds="

# Process all pages (1383 persons divided by 10 per page = 138 pages)
while [ $PAGE -lt $PAGELIMIT ]
do
	# Special handling for subsequent pages after the first...
	if [ $PAGE -gt 1 ]
	then
		# Use only page form element for subsequent page searches...
		FORMDATA="listOrFlyer_1=List&listOrFlyer_2=List&link=doSearch&prevLink=&includeFirstName=false&includeLastName=false&includeCounty=false&includeZip=false&firstName=&lastName=&city=Miami&county=Miami-Dade&outOfFloridaCounty=&zip=&includeThumbnail=false&includeAliases=true&searchAllWanted=false&offenderType=3&lglStatus_1=1&lglStatus_6=6&lglStatus_7=7&lglStatus_8=8&lglStatus_9=9&stateStatus=1&link=doSearch&commaSeparatedOffenderStatus=1%2C6%2C7%2C8%2C9&commaSeparatedPersonIds=&commaSeparatedPersonIdsALL=$COMMASEPARATEDPERSONIDSALL&totalResultsCount=$TOTALRESULTSCOUNT&page=$PAGE"
	fi

	# Construct the page directory path
	PAGE_DIRECTORY_PATH="$PAGE_DIRECTORY/page_$PAGE.html"
	ONE_LINE_PATH="$PAGE_DIRECTORY/one_line.$PAGE"
	ONE_LINE_PATH2="$PAGE_DIRECTORY/one_line_stage2.$PAGE"

	# Send request to retrieve a page of results...
	curl --data "$FORMDATA" --cookie newcookies.txt http://offender.fdle.state.fl.us/offender/offenderSearchNav.do > $PAGE_DIRECTORY_PATH 2>&1

	# Additional processing for first page...
	if [ $PAGE -eq 1 ]
	then
		# The initial search query result contains a list of comma separated person ids that are used
		# in navigating from page to page to see result sets.  To accommodate this mechanism,
		# we will extract a copy of the comma separated person ids and inject them as part of
		# our form data for the http post submissions for each page

		# Extract the commaSeparatedPersonIds where 'name="commaSeparatedPersonIdsALL" value="XXX"'
		COMMASEPARATEDPERSONIDSALL=`grep \"commaSeparatedPersonIdsALL\" $PAGE_DIRECTORY_PATH | awk -F"value=" '{ print $2 }' | awk -F'"' '{ print $2 }' | sed -e $'s/,/%2C/g'` 
		#echo "commaSeparatedPersonIdsALL = $COMMASEPARATEDPERSONIDSALL"

		# Extract the totalResultsCount where 'name="totalResultsCount" value="XXX"'
		TOTALRESULTSCOUNT=`grep \"totalResultsCount\" $PAGE_DIRECTORY_PATH | awk -F"value=" '{ print $2 }' | awk -F'"' '{ print $2 }'` 
		#echo "totalResultsCount = $TOTALRESULTSCOUNT"

		# Recalculate our page limit based on actual results contained in FDLE database (10 per page)
		PAGELIMIT=`expr $TOTALRESULTSCOUNT / 10`
	fi

	# Process the page...
	echo "Processing page $PAGE."
	# Convert page into a single line...
	echo $(cat $PAGE_DIRECTORY_PATH) | iconv -f iso-8859-1 -t utf-8 > $ONE_LINE_PATH
	# Split line by "showGoogleMap("
	cat $ONE_LINE_PATH | LC_CTYPE=C sed -e $'s/showGoogleMap/showGoogleMap\\\n/g' | sed -e 's///g'  > $ONE_LINE_PATH2

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

		# Extract name, personID, imageID, subjectType, addressLine1, addressLine2, city, state, zip, county, latitude, longitude
		NAME=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $2 }'`
		if [ "$NAME" == "" ]
		then
			# NAME is empty, skip this incomplete record...
			continue
		fi

		LASTNAME=`echo $NAME | awk -F',' '{ print $1 }'`
		FIRSTNAME=`echo $NAME | awk -F',' '{ print $2 }'`
		PERSONID=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $4 }'`
		IMAGEID=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $6 }'`
		SUBJECTYPE=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $8 }'`
		ADDRESSLINE1=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $10 }'`
		ADDRESSLINE2=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $12 }'`
		CITY=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $14 }'`
		STATE=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $16 }'`
		ZIP=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $18 }'`
		COUNTY=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $20 }'`
		LATITUDE=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $22 }'`
		LONGITUDE=`echo $line | awk -F'(' '{ print $2 }' | awk -F"'" '{ print $24 }'`
		echo "$LASTNAME, $FIRSTNAME, $PERSONID, $IMAGEID, $SUBJECTYPE, $ADDRESSLINE1, $ADDRESSLINE2, $CITY, $STATE, $ZIP, $COUNTY, $LATITUDE, $LONGITUDE"
		echo "$LASTNAME, $FIRSTNAME, $PERSONID, $IMAGEID, $SUBJECTYPE, $ADDRESSLINE1, $ADDRESSLINE2, $CITY, $STATE, $ZIP, $COUNTY, $LATITUDE, $LONGITUDE" >> $CRIMEDATA
	done < $ONE_LINE_PATH2

	# Increment our page counter
	PAGE=`expr $PAGE + 1`
done

echo "Done processing, look at $CRIMEDATA for csv results."
