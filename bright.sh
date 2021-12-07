#!/bin/bash
# changeVolume

# Arbitrary but unique message tag
msgTag="mybrightness"


# Query amixer for the current volume and whether or not the speaker is muted
bright="$(xbacklight -get | xargs printf '%.0f')"
    # Show the volume notification
    dunstify -a "changeBrightness" -u critical -i brightness -h string:x-dunst-stack-tag:$msgTag \
    -h int:value:"$bright" "Brightness: ${bright}%" -r 16 -t 2000 -I /home/stefanj/.config/awesome/themes/powerarrow-blue/icons/bright.png

# Play the volume changed sound
canberra-gtk-play -i audio-volume-change -d "changeVolume"
