#!/bin/bash

# $1 the line that will be append into the map
# $2 the path of map file

./../utils/check-global-point-name.sh $1 || exit 1

var=${1%=*}
val=${1#*=}

while read -r line; do
    if [[ $var == ${line%=*} ]] && [[ $val == ${line#*=} ]] ; then
        return
    fi
done < <(./read.sh $2)
echo "$var=$val" >> $2
