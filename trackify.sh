#!/bin/bash

string=$1

wget -q -O tmp.html "$string"

# Echo out track number
grep music:album:track tmp.html | sed 's/.*music:album:track" content="\([^ ]*\)".*/\1/'

string=$(grep og:image tmp.html |head -n 1 | sed 's/.*og:image" content="\([^ ]*\)".*/\1/')
wget -q -O cover.jpg "$string"

rm -f tmp.html
