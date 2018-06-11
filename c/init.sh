#!/bin/bash

# $1 the path of RC file
# $2 the point name

# to create a .tox file in home dir if it not exists
if [ ! -f $1 ]; then
    touch $1
    echo '# setting ignore files' >> $1
    echo "TOX_POINT=$2" >> $1
    echo 'TOX_IGNORE=node_modules,logs,.*' >> $1
    exit 0
fi
exit 1
