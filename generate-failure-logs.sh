#!/bin/bash

FAILURES_STR=$(deckard list-failures -o $@)
IFS=$'\n' read -rd '' -a FAILURES <<<"$FAILURES_STR"

mkdir -p logs

for FAILURE in "${FAILURES[@]}"; do
  TIMESTAMP=$(echo $FAILURE | awk '{print $1}')
  UUID=$(echo $FAILURE | awk '{print $3}')
  FILENAME="logs/${TIMESTAMP}_${UUID}.log"
  echo "writing: $FILENAME"

  LOG=$(deckard trace $UUID)
  FLOW_UUID=$(echo "$LOG" | grep 'FLOWUUID' | awk '{print $2}')
  FLOW_ACTIVITY=$(deckard flow-activity $FLOW_UUID)

  STOP_STARTS=$(echo "$FLOW_ACTIVITY" | grep 'app-octoblu' | grep 'begin')

  echo "$LOG" > $FILENAME
  echo $'\n\nFLOW ACTIVITY\n' >> $FILENAME
  echo "$FLOW_ACTIVITY" >> $FILENAME
  echo $'\n\nFLOW STOP STARTS\n' >> $FILENAME
  echo "$STOP_STARTS" >> $FILENAME
done
