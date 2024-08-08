#!/bin/bash
# Author: Ruben Lopez (Logon84) <rubenlogon@yahoo.es>
# Description: A shell script to switch pipewire sinks (outputs). Optinally it requires notify-send.sh for showing notifications.

# Add sink names (separated with '|') to SKIP while switching with this script. Choose names to skip from the output of this command:
# wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─ )' | grep -a "vol:"
# if no skip names are added, this script will switch between every available audio sink (output).
SINKS_TO_SKIP=("other_sink_name1|other_sink_name2|other_sink_name3")

#Create array of sink names to switch to
declare -a SINKS_TO_SWITCH=($(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a "vol:" | tr -d \* | awk '{print ($3)}' | grep -Ev $SINKS_TO_SKIP))
SINK_ELEMENTS=$(echo ${#SINKS_TO_SWITCH[@]})

#get current sink name and array position
ACTIVE_SINK_NAME=$(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a '*' | awk '{print ($4)}')
ACTIVE_ARRAY_INDEX=$(echo ${SINKS_TO_SWITCH[@]/$ACTIVE_SINK_NAME//} | cut -d/ -f1 | wc -w | tr -d ' ')

#get next array name and then its ID to switch to
NEXT_ARRAY_INDEX=$((($ACTIVE_ARRAY_INDEX+1)%$SINK_ELEMENTS))
NEXT_SINK_NAME=${SINKS_TO_SWITCH[$NEXT_ARRAY_INDEX]}
NEXT_SINK_ID=$(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a $NEXT_SINK_NAME | awk '{print ($2+0)}')

#switch to sink & notify
wpctl set-default $NEXT_SINK_ID
notify-send.sh -s $(</tmp/sss.id) || true && notify-send.sh Audioswitch "Switching to $NEXT_SINK_ID : $NEXT_SINK_NAME" -p > /tmp/sss.id || true
