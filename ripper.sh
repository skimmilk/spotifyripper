#!/bin/bash

if [[ -z $1 ]]; then
  musicdir="."
else
  musicdir=$1
fi

./notify.sh | while read line
do
  if [[ $line == "__SWITCH__" ]]; then
    killall oggenc 2> /dev/null
    killall pacat 2> /dev/null
    if [[ -n $title ]]; then
      vorbiscomment -a tmp.ogg -t "ARTIST=$artist" -t "ALBUM=$album"\
          -t "TITLE=$title" -t "tracknumber=$tracknumber"
      # Sanitize filenames
      saveto="$musicdir/${artist//\/ /}/${album//\/ /}"
      echo "Saved song $title by $artist to $saveto/${title//\/ /}.ogg"
      if [[ ! -a $saveto ]]; then
        mkdir -p "$saveto"
      fi
      mv tmp.ogg "$saveto/${title//\/ /}.ogg"
      if [[ -s cover.jpg ]] && [[ ! -a "$saveto/cover.jpg" ]]; then
        mv cover.jpg "$saveto/cover.jpg"
      fi
      artist=""
      album=""
      title=""
      tracknumber=""
      rm -f cover.jpg
    fi
    echo "RECORDING"
    # Another reinstallation of Ubuntu, another thing broken
    #pacat --record -d 1 | oggenc -b 192 -o tmp.ogg --raw - 2>/dev/null &
    parec --format=s16le \
          --device="$(pactl list | grep "Monitor Source" \
              | head -n1 | awk '{ print $3 }')" \
          | oggenc -b 192 -o tmp.ogg --raw - 2>/dev/null &

  else
    variant=$(echo "$line"|cut -d= -f1)
    string=$(echo "$line"|cut -d= -f2)
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
      # Much much easier to debug
      # url comes last after artist info
      tracknumber="$(./trackify.sh $string $title)"
      echo "Track number = $tracknumber"
    fi
  fi
done
