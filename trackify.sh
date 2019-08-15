#!/bin/bash

string="https:$(wget -q -O - $1 | grep background-image | cut -d '(' -f2 | cut -d ')' -f1)"
wget -q -O cover.jpg "$string"
