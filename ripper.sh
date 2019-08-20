#!/bin/bash

script_dir=$(dirname $(readlink -f $0))
export TEMP_DIR=/tmp/spotifyripper.$$

if [[ -z $1 ]]; then
  musicdir="."
else
  musicdir=$1
fi

function cleanup {
  rm -f ${TEMP_DIR}/*.jpg ${TEMP_DIR}/*.ogg
  rm -d ${TEMP_DIR}
}

# cleanup temporary directory
trap cleanup SIGINT

# create temporary directory
[ -d ${TEMP_DIR} ] || mkdir ${TEMP_DIR}

# Get the client index of Spotify
spotify=$(pacmd list-sink-inputs | while read line; do
  [[ -n $(echo $line | grep "index:") ]] && index=$line
  [[ -n $(echo $line | grep Spotify) ]] && echo $index && exit
done | cut -d: -f2)

if [[ -z $spotify ]]; then
  echo "Spotify is not running"
  exit
fi

# Determine if spotify.monitor is already set up
if [[ -z $(pactl list short | grep spotify.monitor) ]]; then
  pactl load-module module-null-sink 'sink_name=spotify'
fi

# Move Spotify sound output back to default at exit
pasink=$(pactl stat | grep Sink | cut -d: -f2)
trap 'pactl move-sink-input $spotify $pasink' EXIT

# Move Spotify to its own sink so recorded output will not get corrupted
pactl move-sink-input $spotify spotify

$script_dir/notify.sh | while read line
do
  if [[ $line == "__SWITCH__" ]]; then
    killall oggenc 2>/dev/null
    killall parec 2>/dev/null

    if [[ -n $title ]]; then
      vorbiscomment -a ${TEMP_DIR}/tmp.ogg -t "ARTIST=$artist" -t "ALBUM=$album"\
          -t "TITLE=$title" -t "tracknumber=$tracknumber"
      # Sanitize filenames
      saveto="$musicdir/${album//\/ /}/"
      if [[ "${DISC_NUMBER}" -gt 1 ]]; then
        saveto="$saveto/DISC${DISC_NUMBER}/"
      fi
      echo "Saved song $title by $artist to $saveto/$(printf "%02d" ${tracknumber}) - ${artist} - ${title//\/ /}.ogg"
      if [[ ! -a $saveto ]]; then
        mkdir -p "$saveto"
      fi
      mv ${TEMP_DIR}/tmp.ogg "$saveto/$(printf "%02d" ${tracknumber}) - ${artist} - ${title//\/ /}.ogg"
      if [[ -s ${TEMP_DIR}/cover.jpg ]] && [[ ! -a "$saveto/cover.jpg" ]]; then
        mv ${TEMP_DIR}/cover.jpg "$saveto/cover.jpg"
      fi
      artist=""
      album=""
      title=""
      tracknumber=""
      DISC_NUMBER=""
      rm -f ${TEMP_DIR}/cover.jpg
    fi
    echo "RECORDING"
    parec -d spotify.monitor | oggenc -b 320 -o ${TEMP_DIR}/tmp.ogg --raw - 2>/dev/null\
      &disown
    trap 'pactl move-sink-input $spotify $pasink && killall oggenc && killall parec' EXIT

  else
    variant=$(echo "$line"|cut -d= -f1)
    string=$(echo "$line"|cut -d= -f2)
    ENTITY=$(wget -q -O - "${string}" | grep Spotify.Entity | cut -d "=" -f 2- | cut -d ";" -f 1)

    # downloaod cover
    ALBUM_IMAGE=$(echo "${ENTITY}" | jq -r '.album.images[] | select(.width == 300) | .url')
    [ -n "${ALBUM_IMAGE}" ] && wget -q -O "${TEMP_DIR}/cover.jpg" "${ALBUM_IMAGE}"

    # get disk no.
    [ -n "${ENTITY}" ] && DISC_NUMBER=$(echo "${ENTITY}" | jq -r '.disc_number')

    if [[ $variant == "artist" ]]; then
      artist="$string"
      echo "Artist = $string"
    elif [[ $variant == "title" ]]; then
      title="$string"
      echo "Title = $string"
    elif [[ $variant == "album" ]]; then
      album="$string"
      echo "Album = $string"
    elif [[ $variant == "url" ]]; then
      # Get the track number and download the coverart using an outside script
      tracknumber=$(echo ${ENTITY} | jq .track_number)
      echo "Track number = $tracknumber"
    fi
  fi
done
