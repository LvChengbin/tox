#!/bin/bash

# $1 the file path of map file
# $2 the point name

./read.sh $1 | while read line; do
    if [[ $2 == ${line%=*} ]]; then
        echo ${line#*=}
    fi
done
