#!/bin/bash

script_dir=$(dirname $(readlink -f $0))

if [[ -z $1 ]]; then
  musicdir="."
else
  musicdir=$1
fi

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
    parec -d spotify.monitor | oggenc -b 192 -o tmp.ogg --raw - 2>/dev/null\
      &disown
    trap 'pactl move-sink-input $spotify $pasink && killall oggenc && killall parec' EXIT

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
      tracknumber=$("$script_dir/trackify.sh" "$string")
      echo "Track number = $tracknumber"
    fi
  fi
done
