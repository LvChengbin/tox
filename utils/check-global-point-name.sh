#!/bin/bash


if [[ $1 == @* ]]; then
    exit 0
fi 
if [[ $2 == "msg" ]]; then
    echo "tox: $1 is not a global point name."
fi
exit 1
