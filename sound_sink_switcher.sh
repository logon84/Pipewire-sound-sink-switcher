#!/bin/bash

#Sink array space-separated. Add or remove sink names to switch to from the output of this command:
#pw-dump | jq '.[] | select(.info.props."media.class"=="Audio/Sink") | .info.props."node.name"'
declare -a SINKS_TO_SWITCH=("alsa_output.pci-0000_00_03.0.hdmi-stereo" "alsa_output.pci-0000_00_1b.0.analog-stereo")
SINK_ELEMENTS=$(echo ${#SINKS_TO_SWITCH[@]})

#get current sink
ACTIVE_SINK_ID=$(wpctl status | sed -n '/Audio/,${p;/Sink endpoints/q}' | grep '*' | awk '{print ($3+0)}')
ACTIVE_SINK_NAME=$(pw-dump | jq '.[] | select(.id=='"$ACTIVE_SINK_ID"') | .info.props."node.name"' | tr -d \")
ACTIVE_ARRAY_INDEX=$(echo ${SINKS_TO_SWITCH[@]/$ACTIVE_SINK_NAME//} | cut -d/ -f1 | wc -w | tr -d ' ')

#get next ID in array
NEXT_ARRAY_INDEX=$((($ACTIVE_ARRAY_INDEX+1)%$SINK_ELEMENTS))
NEXT_SINK_NAME=${SINKS_TO_SWITCH[$NEXT_ARRAY_INDEX]}
NEXT_SINK_ID=$(pw-dump | jq '.[] | select(.info.props."node.name"=="'"$NEXT_SINK_NAME"'") | .id')

#switch to sink & notify
wpctl set-default $NEXT_SINK_ID
notify-send.sh -s $(</tmp/sss.id) || true && notify-send.sh Audioswitch "Switching to $NEXT_SINK_ID : $NEXT_SINK_NAME" -p > /tmp/sss.id || true
