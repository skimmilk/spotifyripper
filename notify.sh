#!/bin/bash

metadata=0
variant=""
dbus-monitor "path=/org/mpris/MediaPlayer2,member=PropertiesChanged"|while read line
do
  col=$(echo "$line" | awk -F '"' '{print $2}')
  if [[ "$col" == "org.mpris.MediaPlayer2.Player" ]]; then
    metadata=1
    variant=""
    echo "__SWITCH__"
  elif (($metadata)); then
    if [[ -n $(echo "$line"|grep "dict entry") ]]; then
      variant=""
    elif [[ -n $variant ]] && [[ $variant != 0 ]]; then
      if [[ -n $col ]]; then
        simplevariant=$(echo "$variant" | cut -d: -f2)
        echo "$simplevariant=$col"
        variant=0
      fi
    elif [[ -n $col ]]; then
      variant="$col"
      # echo "variant = $col"
    fi
  fi
done
