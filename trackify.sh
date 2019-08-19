#!/bin/bash

ENTITY=$(wget -q -O - "${1}" | grep Spotify.Entity | cut -d "=" -f 2- | cut -d ";" -f 1)

# downloaod cover
ALBUM_IMAGE=$(echo ${ENTITY} | jq -r '.album.images[] | select(.width == 300) | .url')
wget -q -O ${TEMP_DIR}/cover.jpg "${ALBUM_IMAGE}"

# return track number
TRACK_NUMBER=$(echo ${ENTITY} | jq .track_number)
echo ${TRACK_NUMBER}
