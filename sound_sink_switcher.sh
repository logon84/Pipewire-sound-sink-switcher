#!/bin/bash
# Author: Ruben Lopez (Logon84) <rubenlogon@yahoo.es>
# Description: A shell script to switch pipewire sinks (outputs). Requires JQ (mandatory) and notify-send.sh (optional).

# Add sink names (separated with '|') to SKIP while switching with this script. Choose names to skip from the output of this command:
# pw-dump | jq '.[] | select(.info.props."media.class"=="Audio/Sink") | .info.props."node.name"'
# if no skip names are added, this script will switch between every available audio sink (output).
SINKS_TO_SKIP=("alsa_output.pci-0000_00_03.0.pro-output-7|alsa_output.pci-0000_00_03.0.pro-output-8|other_sink_name")

#Create array of sink names to switch to
declare -a SINKS_TO_SWITCH=($(pw-dump | jq '.[] | select(.info.props."media.class"=="Audio/Sink") | .info.props."node.name"' | grep -Ev $SINKS_TO_SKIP))
SINK_ELEMENTS=$(echo ${#SINKS_TO_SWITCH[@]})

#get current sink id, name and array position
ACTIVE_SINK_ID=$(wpctl status | sed -n '/Audio/,${p;/Sink endpoints/q}' | grep '*' | awk '{print ($3+0)}')
ACTIVE_SINK_NAME=$(pw-dump | jq '.[] | select(.id=='"$ACTIVE_SINK_ID"') | .info.props."node.name"')
ACTIVE_ARRAY_INDEX=$(echo ${SINKS_TO_SWITCH[@]/$ACTIVE_SINK_NAME//} | cut -d/ -f1 | wc -w | tr -d ' ')

#get next array name and then its ID to switch to
NEXT_ARRAY_INDEX=$((($ACTIVE_ARRAY_INDEX+1)%$SINK_ELEMENTS))
NEXT_SINK_NAME=${SINKS_TO_SWITCH[$NEXT_ARRAY_INDEX]}
NEXT_SINK_ID=$(pw-dump | jq '.[] | select(.info.props."node.name"=='"$NEXT_SINK_NAME"') | .id')

#switch to sink & notify
wpctl set-default $NEXT_SINK_ID
notify-send.sh -s $(</tmp/sss.id) || true && notify-send.sh Audioswitch "Switching to $NEXT_SINK_ID : $NEXT_SINK_NAME" -p > /tmp/sss.id || true
