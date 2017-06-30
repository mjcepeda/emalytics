#!/bin/bash
#
# Eric Hartman (ech6581@rit.edu)
# CSCI-620 Introduction to Big Data
#
# water.sh
#
#   Significant dependencies:
#     -Google Static Maps API
#     -ImageMagick image processing package
#
#   This is a script to calculate a field of latitude and longitude coordinates that covers
#   the geographic area representing the city of Miami, Florida as a collection of evenly distributed
#   points.
#
#   Once the points have been calculated, a 1x1 pixel map will be downloaded from Google Static Maps
#   API in order to determine if the point represents a land or water feature.  The points that represent
#   water features will be exported to a csv file for use as data points in our real estate pricing model.
#
#   Since we are using the free version of the Google Static Maps API, we will be limited to approximately 
#   2500 points.
#

# Enter the API Key that has access to Google Reverse Geocoding Services
APIKEY="AIzaSyAPi2ZJtMrtQPCR5RQ27DauSOdMQlpfNck"
# Enter the API Key that has access to Google Static Maps Services
#APIKEY="AIzaSyAnaXihLbvyWfQQpVmKMOImNKJDWTq82Ek"

# Storage location for artifacts...
PAGE_DIRECTORY="./www"

# Create PAGE_DIRECTORY if it does not already exist
if [ ! -d $PAGE_DIRECTORY ]
then
	echo "Creating $PAGE_DIRECTORY for artifacts..."
	mkdir $PAGE_DIRECTORY
fi

# Output file water.csv
CSV_FILE="$PAGE_DIRECTORY/water.csv"

# Initialize header of output file...
echo "ID, COLOR, LATITUDE, LONGITUDE" > $CSV_FILE

# Color value for water in Google Static Maps
WATER_BLUE="#A3CBFF"

# Top right coordinate for Miami, FL (visually selected from Google Maps)
# Latitude  = 25.875632
# Longitude = -80.113246
topRightLatitude=25.875632
topRightLongitude=-80.113246

# Bottom left coordinate for Miami, FL (visually selected from Google Maps)
# Latitude  = 25.709808 
# Longitude = -80.313985
bottomLeftLatitude=25.709808
bottomLeftLongitude=-80.313985

# Calculate the vertical delta
longitudeDelta=`echo $topRightLongitude - $bottomLeftLongitude | bc`

# Calculate the horizontal delta
latitudeDelta=`echo $topRightLatitude - $bottomLeftLatitude | bc`

echo "Longitude Delta = $longitudeDelta"
echo "Latitude Delta  = $latitudeDelta"

maxPoints=2400
currentLatitude=$bottomLeftLatitude
#currentLatitude=`echo $topRightLatitude - 0.004 | bc`
currentLongitude=$bottomLeftLongitude
#currentLongitude=`echo $topRightLongitude - 0.004 | bc`
#blockSize="0.005" # generates 1394 equidistant blocks
#blockSize="0.003" # generates 3753 equidistant blocks
blockSize="0.004"  # generates 2142 equidistant blocks across Miami, FL
blocksLatitude=0
blocksTotal=0

# Walk through all of the latitude blocks left to right
echo "currentLatitude=$currentLatitude, topRightLatitude=$topRightLatitude"
while [ $(echo "$currentLatitude < $topRightLatitude" | bc -l) -eq 1 ]
do
	# For each latitude, walk through all of the longitude blocks top to bottom
	echo "currentLongitude=$currentLongitude, bottomLeftLongitude=$bottomLeftLongitude"
	while [ $(echo "$currentLongitude < $topRightLongitude" | bc -l) -eq 1 ]
	do	
		# Construct our Google API URL
		#https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&key=AIzaSyAPi2ZJtMrtQPCR5RQ27DauSOdMQlpfNck
		
		#GEOCODINGURL="https://maps.googleapis.com/maps/api/geocode/json?latlng=$currentLatitude,$currentLongitude&$key=$APIKEY"
		GEOCODINGURL="http://maps.googleapis.com/maps/api/staticmap?center=$currentLatitude,$currentLongitude&zoom=15&size=1x1&maptype=roadmap&sensor=false&format=png&key=$APIKEY"
		GEOCODINGPATH="$PAGE_DIRECTORY/water_geocoding.$blocksTotal"
		GEOCODINGPATH="$PAGE_DIRECTORY/water_geocoding_$blocksTotal.png"
		curl --cookie newcookies.txt $GEOCODINGURL > $GEOCODINGPATH 
		echo "URL = $GEOCODINGURL"

		# Identify the color of the 1x1 pixel in the downloaded map	
		COLOR=`convert $GEOCODINGPATH txt:- | tail -n 1 | awk '{ print $3 }'`
		if [ "$COLOR" == "$WATER_BLUE" ]
		then
			echo "Found a water point: $currentLatitude, $currentLongitude"
		fi
		echo "$blocksTotal, $COLOR, $currentLatitude, $currentLongitude" >> $CSV_FILE
		echo "$blocksTotal, $COLOR, $currentLatitude, $currentLongitude"

		# Increment our longitude
		currentLongitude=`echo $currentLongitude + $blockSize | bc`
		blocksTotal=`echo $blocksTotal + 1 | bc`

		echo "$currentLatitude,$currentLongitude: Blocks Total: $blocksTotal, BlocksLat: $blocksLatitude"
		sleep 1
	done

	echo "Next latitude"
	# Reset our longitude
	currentLongitude=$bottomLeftLongitude

	# Increment our latitude
	currentLatitude=`echo $currentLatitude + $blockSize | bc`
	blocksLatitude=`echo $blocksLatitude + 1 | bc`
	sleep 1	
done 
