#!/bin/bash

# Check if Firefox is already running
if pgrep -x "firefox" > /dev/null
then
    # If Firefox is running, focus the window
     bspc desktop -f ^7 && null
else
    # If Firefox is not running, launch it
    bspc desktop -f ^7 && firefox
fi

