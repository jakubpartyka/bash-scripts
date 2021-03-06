#!/bin/bash

# this script reports all IP addresses from specified input file using AbuseIPDB

key="yout_api_key_here"


cnt=0;
for line in $(cat "$1") ; do

IP="$line"

curl https://api.abuseipdb.com/api/v2/report \
  --data-urlencode "ip=$IP" \
  -d categories=18,22 \
  --data-urlencode "comment=Repetitive SSH login attempts." \
  -H "Key: $key" \
  -H "Accept: application/json";

  echo

  ((cnt++))
done

echo -e "\n$cnt ip addresses reported!"
