#!/bin/bash

# $1 the line that will be deleted
# $2 the path of map file

./../utils/check-global-point-name.sh $1 || exit 1

# to remove the item from map file
while read -r line; do
    [[ ! $line == $1 ]] && echo "$line"
done < $2 > map-remove-output
mv map-remove-output $2
