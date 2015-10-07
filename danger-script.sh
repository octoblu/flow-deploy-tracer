#!/bin/bash

FLOW_UUIDS_RAW=$(grep 'FLOWUUID' logs/*.log | awk '{print $2}' | sort | uniq)
IFS=$'\n' read -rd '' -a FLOW_UUIDS <<<"$FLOW_UUIDS_RAW"

for FLOW_UUID in "${FLOW_UUIDS[@]}"; do
  echo $FLOW_UUID
  ssh mongodb-mongodb1 mongo --quiet --host mongo-rs/localhost meshblu --eval "\"printjson(db.devices.findOne({uuid: '${FLOW_UUID}'}, {uuid: true, nanocyteBeta: true}))\"" | grep -v 'Wed Oct  7'
done
