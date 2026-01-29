#!/bin/bash
# Author: Ruben Lopez (Logon84) <rubenlogon@yahoo.es>
# Description: A shell script to switch pipewire sinks (outputs).

# Add sink names (separated with '|') to SKIP while switching with this script. Choose names to skip from the output of this command:
# wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a "vol:"
# if no skip names are added, this script will switch between every available audio sink (output).
SINKS_TO_SKIP=("skip_sink_name1|skip_sink_name2|skip_sink_name3")

#Define Aliases (OPTIONAL)
ALIASES="sink_name1:ALIAS1\nsink_name2:ALIAS2\nsink_name3:ALIAS3"

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
gdbus call --session \
             --dest org.freedesktop.Notifications \
             --object-path /org/freedesktop/Notifications \
             --method org.freedesktop.Notifications.CloseNotification \
             "$(cat /tmp/sss.id 2>/dev/null)" > /dev/null 2>&1
ALIAS=$(echo -e $ALIASES | grep $NEXT_SINK_NAME | awk -F ':' '{print ($2)}')
gdbus call --session \
             --dest org.freedesktop.Notifications \
             --object-path /org/freedesktop/Notifications \
             --method org.freedesktop.Notifications.Notify \
             'Sound Sink Switcher' 0 audio-volume-high \
             "Sound Sink Switcher" "Switching to $NEXT_SINK_ID : $NEXT_SINK_NAME ($ALIAS)" [] \
             "{'transient': <true>}" 5000 \
             | sed 's/(uint32 \([0-9]\+\),)/\1/g' > /tmp/sss.id

#Replace notification icon (optional and only if you use commandLauncher@scollins cinnamon widget)
#ICONS="sink_name1:/usr/share/icons/Adwaita/symbolic/status/amp_stereo_system.png\nsink_name2:audio-headphones"
#ICON=$(echo $(echo -e $ICONS | grep $NEXT_SINK_NAME || echo ":/usr/share/icons/Adwaita/symbolic/status/dialog-question-symbolic.svg") | awk -F ':' '{print ($2)}')
#eval DEST="~/.config/cinnamon/spices/commandLauncher\@scollins/25.json"
#jq '.panelIcon.value|="'"$ICON"'"' $DEST > /tmp/25.json && mv /tmp/25.json $DEST
#dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:'commandLauncher@scollins' string:'APPLET'
