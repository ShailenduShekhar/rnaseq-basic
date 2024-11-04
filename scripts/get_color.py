#!/usr/bin/python

import sys

# color dict
colors = {
    "nc":"\033[0m",
    "red":"\033[0;31m",
    "blue":"\033[01;34m",
    "brown-orange":"\033[0;33m",
    "pink":"\033[0;35m",
    "green": "\033[0;32m"
}

if len(sys.argv) > 1:
    color = sys.argv[1]
    print(colors.get(color, colors.get("nc")))
else:
    print("No color specified")
