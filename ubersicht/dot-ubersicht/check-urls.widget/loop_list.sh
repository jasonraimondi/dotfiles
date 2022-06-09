#!/bin/bash

while IFS= read -r line; do
  [ -z "$line" ] && continue
  [[ "$line" =~ ^#.*$ ]] && continue
  check-urls.widget/curl_check.sh $line
done < "$1"
