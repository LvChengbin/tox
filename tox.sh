#!/bin/bash

# tox d~ : go to the root of the tox dir
# tox path : go to ~/path
# tox - : go to the previous path
# tox . path : to look for the dir from current dir
# tox .. path : to look for the dir from .. dir
# tox 

TOX_BASE=$HOME

TOX_SEARCH_RESULT=()
TOX_FIND=

function _tox_absolute() {
    if [ ! -d $1 ]; then
        echo "tox: no such directory: $1"
        return 0
    fi
    if [ ! -r $1 ];then
        echo "tox: permission denied: $1"
        return 0
    fi
    echo $1
    cd $1
    return 1
}

function _tox_relative() {
    if [ ! -d $PWD/$1 ]; then

        # if the path is a file, return 0
        if [ -f $PWD/$1 ]; then
            echo "tox: not a directory: $1"
            return 0
        fi

        # if the path starts with a ., return 0
        if [[ $1 == .* ]]; then
            echo "tox: no such directory: $1"
            return 0
        fi
        return 2
    fi
    if [ ! -r $1 ];then
        echo "tox: permission denied: $1"
        return 0
    fi
    echo "$1"
    cd $1
    return 1
}

function _tox_base() {
    local D=$PWD
    while true ; do
        # found the .tox file
        if [ -f $D/$TOX_RC ]; then
            . $D/$TOX_RC
            if [[ $1 == "" ]]; then
                _TOX_BASE=$D
                return
            fi
            if [[ "$TOX_POINT" == "$1"  ]]; then
                _TOX_BASE=$D
                return
            fi
        fi

        if [[ $D == "/" ]]; then
            _TOX_BASE=$HOME
            break
        fi
        D=`dirname $D`
    done
}

function _tox_rc() {
    if [ -f $_TOX_BASE/$TOX_RC ]; then
        . $_TOX_BASE/$TOX_RC 
    fi
}

function _tox_find() {
    if [ -z "$TOX_IGNORE" ]; then
        TOX_FIND=""
        return
    fi

    local OIFS="$IFS"
    
    IFS=','
    local TOX_FIND_EXCLUDE_LIST=(`echo $TOX_IGNORE`)
    IFS="$OIFS"

    TOX_FIND=""

    local item
    for item in ${TOX_FIND_EXCLUDE_LIST[@]}; do
        if [[ $item == */* ]]; then
            TOX_FIND+=" -type d -path $item -prune -o "
        else
            TOX_FIND+=" -type d -name $item -prune -o "
        fi
    done
}

function _tox_search() {
    local DIR=`basename $1`
    local LIST=()
    _tox_find
    # find $2 -type d -name "*$DIR*"
    while read -r line; do
        LIST+=("$line")
    done < <(find $2 `echo $TOX_FIND` -type d -name "*$DIR*" -print)

    if [ ${#LIST[@]} -eq 0 ]; then
        TOX_SEARCH_RESULT=()
        return 0 
    fi
    TOX_SEARCH_RESULT=("${LIST[@]}")
    return 1
}

function _tox_goto() {

    # if the target path is a absolute path, just try cd to the path.
    if [[ $1 == /* ]]; then
        _tox_absolute $1
        return
    fi
    # if the target path is a relative path, try cd to the path. If the path not exists, search the path in $PWD.
    _tox_relative $1
    # 2 means the path is able to be looked up in $PWD.
    if [ $? -eq 2 ]; then
        _tox_search $1 $2

        if [ $? -eq 0 ]; then
            return;
        fi

        # if there is only one searching result, cd to the result dir directly.
        if [ ${#TOX_SEARCH_RESULT[@]} -eq 1 ]; then
            _tox_absolute ${TOX_SEARCH_RESULT[1]}                 
            return
        fi

        # list searching results
        local PATH_L=${#2}
        local PREFIX_L=$(expr $PATH_L + 1 )

        local I=0
        local item
        local S

        for item in ${TOX_SEARCH_RESULT[@]}; do
            I=$(expr ${I} + 1)
            S=${item:${PREFIX_L}}

            echo $I: $S | sed "s/$1/$(tput setaf 1)&$(tput sgr0)/g"
        done

        printf "type the index: "
        read -r INDEX

        # if has gotten a q(uit)
        if [[ $INDEX == "q" ]]; then
            return
        fi

        # if enter is pressed directly
        if [[ $INDEX == "" ]]; then
            return 
        fi

        # if the input is not a number
        if ! [[ $INDEX =~ '^[0-9]+$' ]]; then
            echo "tox: invalid option"
            return
        fi

        # if the number is bigger than the length of the list
        if [ $INDEX -le ${#TOX_SEARCH_RESULT[@]} ]; then
            _tox_absolute ${TOX_SEARCH_RESULT[$INDEX]}
        else
            echo "tox: no matching items"
        fi
    fi
}


function tox() {
    if [ $# -eq 0 ]; then
        _tox_base
        _tox_absolute $_TOX_BASE
        return
    fi

    if [[ $1 == "-" ]]; then
        cd -
        return
    fi

    if [[ $1 == @* ]]; then
        _tox_base ${1:1}
        if [ $# -eq 1 ]; then
            _tox_absolute $_TOX_BASE
            return
        else
            _tox_goto $2 $_TOX_BASE
        fi
        return
    fi

    _tox_base
    _tox_goto $1 $_TOX_BASE
}
