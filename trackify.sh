#!/bin/bash

string=$(echo "$1" | cut -d: -f3)
string="http://open.spotify.com/track/$string"
wget -qO- $string > tmp.html

# Echo out track number
grep 'class="track" itemprop="name"' tmp.html |\
        cut -d '>' -f2 | cut -d '<' -f1 | cat -n |\
        grep "$2" | awk '{print $1}' | head -n1

string=$(grep "big-cover" tmp.html | cut -d'"' -f2)
wget -qO- "$string" > cover.jpg

rm -f tmp.html
