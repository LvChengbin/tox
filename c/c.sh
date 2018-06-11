#!/bin/bash

# $1 path of tox dir
# $2 path of map file
# $3 path of rc file

# to create a hidden dir for tox
if [ ! -d $1 ]; then
    mkdir $1 || exit 1
fi

# to create map file
if [ ! -f $2 ]; then
    touch $2 || exit 1
fi

# to create rc file in home dir
if [ ! -f $3 ]; then
    touch $3 || exit 1
fi

$(dirname "$0")/init.sh $3 "@@@@" || exit 1

exit 0
