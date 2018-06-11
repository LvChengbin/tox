#!/bin/bash

UTILS=$(dirname "$0")/../utils

$UTILS/read-file.sh | while read line; do

    key=`$UTILS/key.sh ${line}`

    if [[ key == $1 ]]; then
        echo  `$UTILS/value.sh ${line}`

    fi
done
