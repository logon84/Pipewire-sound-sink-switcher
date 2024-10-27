#!/bin/bash
# Author: Ruben Lopez (Logon84) <rubenlogon@yahoo.es>
# Description: A shell script to switch pipewire sinks (outputs).

# Add sink names (separated with '|') to SKIP while switching with this script. Choose names to skip from the output of this command:
# wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a "vol:"
# if no skip names are added, this script will switch between every available audio sink (output).
SINKS_TO_SKIP=("other_sink_name1|other_sink_name2|other_sink_name3")

#Define Aliases (OPTIONAL)
ALIASES="sink_name1:ALIAS1\nsink_name2:ALIAS2"

#Create array of sink names to switch to
declare -a SINKS_TO_SWITCH=($(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a "vol:" | tr -d \* | awk '{print ($3)}' | grep -Ev $SINKS_TO_SKIP))
SINK_ELEMENTS=$(echo ${#SINKS_TO_SWITCH[@]})

#Get current sink name and array position
ACTIVE_SINK_NAME=$(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a '*' | awk '{print ($4)}')
ACTIVE_ARRAY_INDEX=$(echo ${SINKS_TO_SWITCH[@]/$ACTIVE_SINK_NAME//} | cut -d/ -f1 | wc -w | tr -d ' ')

#Get next array name and then its ID to switch to
NEXT_ARRAY_INDEX=$((($ACTIVE_ARRAY_INDEX+1)%$SINK_ELEMENTS))
NEXT_SINK_NAME=${SINKS_TO_SWITCH[$NEXT_ARRAY_INDEX]}
NEXT_SINK_ID=$(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a $NEXT_SINK_NAME | awk '{print ($2+0)}')

#Switch to sink & notify
wpctl set-default $NEXT_SINK_ID
$(gdbus call --session \
             --dest org.freedesktop.Notifications \
             --object-path /org/freedesktop/Notifications \
             --method org.freedesktop.Notifications.CloseNotification \
             "$(</tmp/sss.id)")
ALIAS=$(echo -e $ALIASES | grep $NEXT_SINK_NAME | awk -F ':' '{print ($2)}')
$(gdbus call --session \
             --dest org.freedesktop.Notifications \
             --object-path /org/freedesktop/Notifications \
             --method org.freedesktop.Notifications.Notify sss \
             0 \
             gtk-dialog-info "Sound Sink Switcher" "Switching to $NEXT_SINK_ID : $NEXT_SINK_NAME ($ALIAS)" [] {} 5000 | \
             sed 's/(uint32 \([0-9]\+\),)/\1/g' > /tmp/sss.id)

#Replace notification icon
#if [ $ALIAS = "HDMI" ]; then
#    sed -i -e 's/audio-headphones/\/usr\/share\/icons\/Adwaita\/symbolic\/status\/amp_stereo_system.png/g' ~/.config/cinnamon/spices/commandLauncher@scollins/25.json
#elif [ $ALIAS = "HEADPHONES" ]; then
#    sed -i -e 's/\/usr\/share\/icons\/Adwaita\/symbolic\/status\/amp_stereo_system.png/audio-headphones/g' ~/.config/cinnamon/spices/commandLauncher@scollins/25.json
#else
#    sed -i -e 's/audio-headphones/\/usr\/share\/icons\/Adwaita\/symbolic\/status\/dialog-question-symbolic/g' ~/.config/cinnamon/spices/commandLauncher@scollins/25.json
#    sed -i -e 's/\/usr\/share\/icons\/Adwaita\/symbolic\/status\/amp_stereo_system.png/\/usr\/share\/icons\/Adwaita\/symbolic\/status\/dialog-question-symbolic/g' ~/.config/cinnamon/spices/commandLauncher@scollins/25.json
#fi
