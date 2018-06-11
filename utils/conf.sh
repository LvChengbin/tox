#!/bin/bash

# $1 path of config name
# $2 key

UTILS=$(dirname "$0")

UTILS/read.sh $1 | while read line; do
    key=`UTILS/key.sh $line`
    if [[ $2 == $key ]]; then
        echo `UTILS/value.sh $line`
    fi
done
