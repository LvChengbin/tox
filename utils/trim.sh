#!/bin/bash

trimmed="$1"

while [[ $trimmed == ' '* ]]; do
   trimmed="${trimmed## }" 
done

while [[ $trimmed == *' ' ]]; do
    trimmed="${trimmed%% }"
done

echo "${trimmed}"
