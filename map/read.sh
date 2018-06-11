#!/bin/bash

while IFS= read -r line || [[ -n "$line" ]]; do

    # skip blank line
    if [[ $line =~ ^[[:blank:]]*$ ]]; then
        continue
    fi

    # skip if the line is comment
    if [[ $line =~ ^[[:blank:]]*#.* ]]; then
        continue 
    fi

    echo "$line"

done < "$1"
