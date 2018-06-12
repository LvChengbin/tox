#!/bin/bash

_TOX_VERSION=0.0.0
_TOX_HOME=$HOME
_TOX_RC=.toxrc
_TOX_HOME_RC=$_TOX_HOME/$_TOX_RC
_TOX_DIR=$_TOX_HOME/.tox
_TOX_MAP_FILE=$_TOX_DIR/map.tox

#################################################################################
# toxc_map
#################################################################################

function _toxc_map_add() {
    _toxc_util_valid_global_point_name $1 || return 1

    while read -r line; do
        if [[ $1 == ${line%=*} ]] && [[ $2 == ${line#*=} ]] ; then
            return 1
        fi
    done < $_TOX_MAP_FILE
    echo "$1=$2" >> $_TOX_MAP_FILE
}

function _toxc_map_remove() {
    _toxc_util_valid_global_point_name $1 || return 1

    while read -r line; do
        [[ ! $line == "$1=$2" ]] && echo "$line"
    done < $_TOX_MAP_FILE > map-remove-output
    mv map-remove-output $_TOX_MAP_FILE
}

function _toxc_map_seek() {
    while read -r line; do
        if [[ $1 == ${line%=*} ]]; then
            echo ${line#*=}
        fi
    done < $_TOX_MAP_FILE
}

function _toxc_map_read() {
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
}

#################################################################################
# toxc_util
#################################################################################

function _toxc_util_valid_global_point_name() {
    if [[ $1 == @* ]]; then
        return 0
    fi 
    if [[ $2 == "msg" ]]; then
        echo "tox: $1 is not a global point name."
    fi
    return 1
}

function _toxc_util_valid_point_name() {
    if [[ $1 == @* ]] || [[ $1 == !@* ]]; then
        return 0
    fi 
    if [[ $2 == "msg" ]]; then
        echo "tox: $1 is not a point name."
    fi
    return 1
}

function _toxc_get_config() {
    while read line; do
        key=`_toxc_util_key $line`
        if [[ $2 == $key ]]; then
            echo `_toxc_util_value $line`
        fi
    done < <(_toxc_util_read_file $1)
}

# _toxc_util_read_file - to read file by line and to skip blank line and comment (lines start with #)
# $1 path of file
function _toxc_util_read_file() {

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
}

function _toxc_util_key() {
    echo `_toxc_util_trim "${1%=*}"`
}

function _toxc_util_value() {
    echo `_toxc_util_trim "${1#*=}"`
}

function _toxc_util_set_value() {
    while read -r line; do
        key=`_toxc_util_key $line`

        if [[ ! $key == $2 ]]; then
            echo "$line"
        else
            echo "$key=$3"
        fi
    done < $1 > set-output
    mv set-output $1
}

function _toxc_util_trim() {
    trimmed="$1"

    while [[ $trimmed == ' '* ]]; do
       trimmed="${trimmed## }" 
    done

    while [[ $trimmed == *' ' ]]; do
        trimmed="${trimmed%% }"
    done

    echo "${trimmed}"
}

#################################################################################
# toxc_point
#################################################################################

# _toxc_point_item
# $1 file name
# $2 key of item
function _toxc_point_item() {
    while read line; do
        key=`_toxc_util_key ${line}`

        if [[ $key == $2 ]]; then
            echo  `_toxc_util_value ${line}`
        fi
    done < <(_toxc_util_read_file $1)
}

# $1 path of rc file
# $2 denoting if split the point names into lines by comma
function _toxc_point_get_name() {
    local points=`_toxc_point_item $1 "point"`

    if [[ $2 -eq 0 ]]; then
        echo $points
        return 0 
    fi

    local OIFS="$IFS"
    IFS=","
    local points=(`echo $points`)
    IFS=$OIFS

    for item in ${points[@]}; do
        echo "`_toxc_util_trim $item`"
    done
}

function _toxc_point_has_name() {
    while read -r line; do
        if [[ $line == "$2" ]] || [[ $line == "!$2" ]]; then
            return 0 
        fi
    done < <(_toxc_point_get_name $1 1)
    return 1
}

function _toxc_point_add_name() {
    while read -r line; do
        if [[ $line == $2 ]]; then
            echo "tox: point name $2 exists in current point."
            return 1
        fi
    done < <(_toxc_point_get_name $1 1)
    local name="`_toxc_point_get_name $1 0`,$2"
    _toxc_util_set_value "$1" "point" "$name" || return 1
}

function _toxc_point_remove_name() {
    local name=""
    while read line; do
        if [[ ! $line == $2 ]]; then
            name+="$line,"
        fi
    done < <(_toxc_point_get_name $1 1)

    _toxc_util_set_value $1 "point" ${name%%,}
}


#################################################################################
# toxc
#################################################################################

function _toxc_nearest_point() {
    local d=$PWD
    while true; do
        if [ -f $D/$_TOX_RC ]; then
            if [[ $1 == "" ]]; then
                echo $D
                return 0 
            fi  
            _toxc_point_has_name $D/$_TOX_RC $1 && {
                
            }
        fi
    done
}

# _tox_c create files and dirs for tox
function _toxc_c() {
    # to create a hidden dir for tox
    if [ ! -d $_TOX_DIR ]; then
        mkdir $_TOX_DIR || return 1
    fi

    # to create map file
    if [ ! -f $_TOX_MAP_FILE ]; then
        touch $_TOX_MAP_FILE || return 1
    fi

    # to create rc file in home dir
    if [ ! -f $_TOX_HOME_RC ]; then
        touch $_TOX_HOME_RC || return 1
    fi

    _toxc_init "$_TOX_HOME_RC" "@@@@" || return 1
    return 0
}

# _toxc_init to initialize a dir as a point
# $1 the path of RC file
# $2 the point name
function _toxc_init() {
    # to create a .tox file in home dir if it not exists
    if [ ! -f $1 ]; then
        touch $1
        echo '# setting ignore files' >> $1
        echo "point=$2" >> $1
        echo 'ignore=node_modules,logs,.*' >> $1
        return 0
    fi
    return 1
}

function toxc() {

    if [ $# -eq 0 ]; then
        echo "tox: version: $_TOX_VERSION"
        _toxc_c

        if [ ! -f $PWD/$_TOX_RC ]; then
            echo "tox: current dir is not a tox point" 
        else
            echo "tox: current point: `_toxc_point_get_name $PWD/$_TOX_RC`"
        fi
        return
    fi

    case $1 in
        init)
            if [[ ! $2 == "" ]]; then
                point=$2 
            else
                printf "point name: (anonymous point)"
                read -r point
            fi

            if [[ ! $point == @* ]] && [[ ! $point == !@* ]]; then
                point="@$point"
            fi

            # to create RC file in current directory
            _toxc_init $PWD/$_TOX_RC $point

            if [[ $point == "@" ]]; then
                echo "tox: anonymous point has been created."
            else
                echo "tox: point $point has been created." 
            fi
            ;;
        add-name)
            if [ ! -f $PWD/$_TOX_RC ]; then
                echo "tox: current directory is not a point."
                return 1
            fi
            if [[ ! $2 == "" ]]; then
                point=$2
            else
                printf "point name: "
                read -r point
            fi

            if [[ $point == "" ]]; then
                return 1
            fi

            if [[ ! $point == @* ]] && [[ ! $point == !@* ]]; then
                echo "tox: point name should start with a \"@\" or \"!@\""
                return 1
            fi

            _toxc_point_add_name $PWD/$_TOX_RC $point || return 1

            _toxc_map_add "$point" "$PWD"

            echo "tox: the name $point has been added to this point."
            echo "tox: existing names of this point: `_toxc_point_get_name $PWD/$_TOX_RC 0`"
            ;;
        remove-name)
            if [[ $2 == "" ]]; then
                echo "tox: please specify a existing point name."
                return 1
            fi

            if [[ ! $2 == @* ]] && [[ ! $2 == !@* ]]; then
                echo "tox: point name should start with a \"@\" or \"!@\""
                return 1
            fi

            _toxc_point_remove_name $PWD/$_TOX_RC $2 || return 1

            _toxc_map_remove "$2" "$PWD"
            echo "tox: point name $2 has been removed from this point"
            echo "tox: existing names of this point: `_toxc_point_get_name $PWD/$_TOX_RC 0`"
            ;;
        uninit|uinit)
            # to remote RC file, if exists, in current directory

            if [ ! -f $PWD/$_TOX_RC ]; then
                echo "tox: cannot find $_TOX_RC in current dir"
                return 0
            fi
            rm -rf $PWD/$_TOX_RC
            echo "tox: this point has been removed."
            ;;
        map)
            _toxc_map_read $_TOX_MAP_FILE
            ;;
        *)
            echo "tox: unknown option \"$1\""
            ;;
    esac
}


#################################################################################
# tox
#################################################################################

function tox() {
}
