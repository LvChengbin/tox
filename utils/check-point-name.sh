#!/bin/bash

if [[ $1 == @* ]] || [[ $1 == !@* ]]; then
    exit 0
fi 
if [[ $2 == "msg" ]]; then
    echo "tox: $1 is not a point name."
fi
exit 1
