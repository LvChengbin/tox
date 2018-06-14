#!/bin/bash

_TOX_VERSION=0.0.1
_TOX_HOME="$HOME"
_TOX_RC=".toxrc"
_TOX_HOME_RC="$_TOX_HOME/$_TOX_RC"
_TOX_DIR="$_TOX_HOME/.tox"
_TOX_MAP_FILE="$_TOX_DIR/map.tox"
_TOX_ECHO_PRE="$(tput setaf 6)tox$(tput sgr0)"

#################################################################################
# toxc_map
#################################################################################

function _toxc_map_add() {
    _toxc_util_valid_global_point_name "$1" || return 1

    while read -r line; do
        if [[ "$1" == "${line%=*}" ]] && [[ "$2" == "${line#*=}" ]] ; then
            return 0
        fi
    done < "$_TOX_MAP_FILE"
    echo "$1=$2" >> "$_TOX_MAP_FILE"
}

function _toxc_map_index() {
    local nearest=`_toxc_point_nearest_point "$1"`
    while read -r line; do
        _toxc_map_add "$line" "$nearest"
    done < <(_toxc_point_get_name "$nearest" 1)
}

function _toxc_map_remove() {
    _toxc_util_valid_global_point_name "$1" || return 1

    while read -r line; do
        [[ ! "$line" == "$1=$2" ]] && echo "$line"
    done < "$_TOX_MAP_FILE" > map-remove-output
    mv map-remove-output "$_TOX_MAP_FILE"
}

function _toxc_map_seek() {
    while read -r line; do
        if [[ "$1" == "${line%=*}" ]]; then
            echo "${line#*=}"
        fi
    done < "$_TOX_MAP_FILE"
}

function _toxc_map_clean() {
    while read -r line; do
        local d="${line#*=}"

        if [ -d "$d" ] && [ -f "$d/$_TOX_RC" ]; then
            echo "$line" 
        fi
    done < <(_toxc_map_read "$_TOX_MAP_FILE") > map-clean-output
    mv map-clean-output "$_TOX_MAP_FILE"
}

function _toxc_map_read() {
    while read -r line || [[ -n "$line" ]]; do

        # skip blank line
        if [[ "$line" =~ ^[[:blank:]]*$ ]]; then
            continue
        fi

        # skip if the line is comment
        if [[ "$line" =~ ^[[:blank:]]*#.* ]]; then
            continue 
        fi

        echo "$line"

    done < "$1"
}

#################################################################################
# toxc_util
#################################################################################

function _toxc_util_valid_global_point_name() {
    if [[ "$1" == @* ]]; then
        return 0
    fi 
    if [[ "$2" == "msg" ]]; then
        echo "$_TOX_ECHO_PRE: $1 is not a global point name."
    fi
    return 1
}

function _toxc_util_valid_point_name() {
    if [[ "$1" == @* ]] || [[ "$1" == !@* ]]; then
        return 0
    fi 
    if [[ "$2" == "msg" ]]; then
        echo "$_TOX_ECHO_PRE: $1 is not a point name."
    fi
    return 1
}

# _toxc_util_read_file - to read file by line and to skip blank line and comment (lines start with #)
# $1 path of file
function _toxc_util_read_file() {

    while read -r line || [[ -n "$line" ]]; do

        # skip blank line
        if [[ "$line" =~ ^[[:blank:]]*$ ]]; then
            continue
        fi

        # skip if the line is comment
        if [[ "$line" =~ ^[[:blank:]]*#.* ]]; then
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
        key=`_toxc_util_key "$line"`

        if [[ ! "$key" == "$2" ]]; then
            echo "$line"
        else
            echo "$key=$3"
        fi
    done < "$1" > set-output
    mv set-output "$1"
}

function _toxc_util_trim() {
    trimmed="$1"

    while [[ "$trimmed" == ' '* ]]; do
       trimmed="${trimmed## }" 
    done

    while [[ "$trimmed" == *' ' ]]; do
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
    local rc
    if [ -d "$1" ]; then
        rc="$1/$_TOX_RC"
    else
        rc="$1"
    fi

    while read line; do
        key=`_toxc_util_key "$line"`

        if [[ "$key" == "$2" ]]; then
            echo  `_toxc_util_value "$line"`
        fi
    done < <(_toxc_util_read_file "$rc")
}

# _toxc_point_get_ignore
function _toxc_point_get_ignore() {
    local ignores
    if [ -f "$1/$_TOX_RC" ]; then
        ignores=`_toxc_point_item "$1" "ignore"` 
    else
        local nearest=`_toxc_point_nearest_point "$1"`
        if [[ ! "$nearest" == "" ]]; then
            ignores=`_toxc_point_item "$nearest" "ignore"` 
        else
            ignores=`_toxc_point_item "$_TOX_HOME_RC" "ignore"`
        fi
    fi

    set +f
    local OIFS="$IFS"
    IFS=","
    local list=(`echo "$ignores"`)
    IFS="$OIFS"

    for item in ${list[@]}; do
        echo "$item"
    done
}

# $1 path of rc file
# $2 denoting if split the point names into lines by comma
function _toxc_point_get_name() {
    local points=`_toxc_point_item "$1" "point"`

    if [[ "$2" -eq 0 ]]; then
        echo "$points"
        return 0 
    fi

    local OIFS="$IFS"
    IFS=","
    local points=(`echo "$points"`)
    IFS="$OIFS"

    for item in ${points[@]}; do
        echo "`_toxc_util_trim "$item"`"
    done
}

function _toxc_point_has_name() {
    while read -r line; do
        if [[ "$line" == "$2" ]] || [[ "$line" == "!$2" ]]; then
            return 0 
        fi
    done < <(_toxc_point_get_name "$1" 1)
    return 1
}

function _toxc_point_add_name() {
    while read -r line; do
        if [[ "$line" == "$2" ]]; then
            echo "$_TOX_ECHO_PRE: point name "$2" exists in current point."
            return 1
        fi
    done < <(_toxc_point_get_name "$1" 1)
    local oname=`_toxc_point_get_name "$1" 0`
    local name="$oname,$2"
    _toxc_util_set_value "$1" "point" "$name" || return 1
}

function _toxc_point_remove_name() {
    local name=""
    while read line; do
        if [[ ! "$line" == "$2" ]]; then
            name+="$line,"
        fi
    done < <(_toxc_point_get_name "$1" 1)

    _toxc_util_set_value "$1" "point" "${name%%,}"
}


#################################################################################
# toxc
#################################################################################

function _toxc_point_nearest_point() {
    local D="$1"
    while true; do
        if [ -f "$D/$_TOX_RC" ]; then
            if [[ "$2" == "" ]]; then
                echo "$D"
                return 0 
            fi  
            if _toxc_point_has_name "$D/$_TOX_RC" "$2"; then
                echo "$D"
                return 0
            fi
        fi
        if [[ "$D" == "/" ]]; then
            break;
        fi
        D=`dirname "$D"`
    done
    return 1
}

# _tox_c create files and dirs for tox
function _toxc_c() {
    # to create a hidden dir for tox
    if [ ! -d "$_TOX_DIR" ]; then
        mkdir "$_TOX_DIR" || return 1
    fi

    # to create map file
    if [ ! -f "$_TOX_MAP_FILE" ]; then
        touch "$_TOX_MAP_FILE" || return 1
    fi

    # to create rc file in home dir
    if [ ! -f "$_TOX_HOME_RC" ]; then
        touch "$_TOX_HOME_RC" || return 1
    fi

    _toxc_init "$_TOX_HOME_RC" "@@@@" || return 1
    return 0
}

# _toxc_init to initialize a dir as a point
# $1 the path of RC file
# $2 the point name
function _toxc_init() {
    # to create a .tox file in home dir if it not exists
    if [ ! -f "$1" ]; then
        touch "$1"
        echo '# setting ignore files' >> "$1"
        echo "point=$2" >> "$1"
        echo 'ignore=node_modules,logs,.*' >> "$1"
        echo 'editor=vim' >> "$1"
        return 0
    fi
}

function toxc() {

    _toxc_map_index "$PWD"

    if [ $# -eq 0 ]; then
        echo "$_TOX_ECHO_PRE: version: $_TOX_VERSION"
        _toxc_c
        return
    fi

    case "$1" in
        init)
            if [ -f "$PWD/$_TOX_RC" ]; then
                echo "$_TOX_ECHO_PRE: current dir is already a tox point"
                echo "$_TOX_ECHO_PRE: to use "toxc add-name" to add name to current point"
                return 1
            fi

            if [[ ! "$2" == "" ]]; then
                point="$2"
            else
                printf "point name: (anonymous point)"
                read -r point
            fi

            if [[ ! "$point" == @* ]] && [[ ! "$point" == !@* ]]; then
                point="@$point"
            fi

            # to create RC file in current directory
            _toxc_init "$PWD/$_TOX_RC" "$point" && _toxc_map_add "$point" "$PWD" || return 1

            if [[ "$point" == "@" ]]; then
                echo "$_TOX_ECHO_PRE: anonymous point has been created."
            else
                echo "$_TOX_ECHO_PRE: point $point has been created." 
            fi
            ;;
        status)
            if [ ! -f "$PWD/$_TOX_RC" ]; then
                echo "$_TOX_ECHO_PRE: current dir is not a tox point" 

                local nearest=`_toxc_point_nearest_point "$PWD"`

                if [[ "$nearest" == "" ]]; then
                    echo "$_TOX_ECHO_PRE: current dir is not inside any tox point"
                    return
                fi

                local name=`_toxc_point_get_name "$nearest/$_TOX_RC"`
                echo "$_TOX_ECHO_PRE: the nearest point is $nearest: $name"
            else
                local name=`_toxc_point_get_name "$PWD/$_TOX_RC"`
                echo "$_TOX_ECHO_PRE: current point: $name"
            fi
            ;;
        add-name)
            if [ ! -f "$PWD/$_TOX_RC" ]; then
                echo "$_TOX_ECHO_PRE: current directory is not a point."
                return 1
            fi
            if [[ ! "$2" == "" ]]; then
                point="$2"
            else
                printf "point name: "
                read -r point
            fi

            if [[ "$point" == "" ]]; then
                return 1
            fi

            if [[ ! "$point" == @* ]] && [[ ! "$point" == !@* ]]; then
                point="@$point"
            fi

            _toxc_point_add_name "$PWD/$_TOX_RC" "$point" || return 1

            _toxc_map_add "$point" "$PWD"

            echo "$_TOX_ECHO_PRE: the name $point has been added to this point."
            echo "$_TOX_ECHO_PRE: existing names of this point: `_toxc_point_get_name $PWD/$_TOX_RC 0`"
            ;;
        remove-name)
            if [[ "$2" == "" ]]; then
                echo "$_TOX_ECHO_PRE: please specify a existing point name."
                return 1
            fi

            if [[ ! "$2" == @* ]] && [[ ! "$2" == !@* ]]; then
                echo "$_TOX_ECHO_PRE: point name should start with a \"@\" or \"!@\""
                return 1
            fi

            _toxc_point_remove_name "$PWD/$_TOX_RC" "$2" && _toxc_map_remove "$2" "$PWD" || return 1
            echo "$_TOX_ECHO_PRE: point name $2 has been removed from this point"
            echo "$_TOX_ECHO_PRE: existing names of this point: `_toxc_point_get_name $PWD/$_TOX_RC 0`"
            ;;
        uninit|uinit)
            # to remote RC file, if exists, in current directory

            if [ ! -f "$PWD/$_TOX_RC" ]; then
                echo "$_TOX_ECHO_PRE: current dir is not a tox point"
                return 0
            fi

            while read line; do
                _toxc_map_remove "$line" "$PWD" || return 1
            done < <(_toxc_point_get_name "$PWD/$_TOX_RC" 1)

            rm -rf "$PWD/$_TOX_RC"
            echo "$_TOX_ECHO_PRE: this point has been removed."
            ;;
        map)
            _toxc_map_clean
            _toxc_map_read "$_TOX_MAP_FILE"
            ;;
        *)
            echo "$_TOX_ECHO_PRE: unknown option \"$1\""
            ;;
    esac
}


#################################################################################
# tox
#################################################################################

function _tox_search() {
    local D=`basename "$2"`
    local prune=""

    while read line; do
        if [[ "$line" == */* ]]; then
            prune+=" -type d -path $line -prune -o " 
        else
            prune+=" -type d -name $line -prune -o "
        fi
    done < <(_toxc_point_get_ignore "$1")

    while read -r line; do
        echo "$line"
    done < <(find "$1" `echo $prune` -type d -name "*$D*" -print)
}

function _tox_to_absolute() {
    if [[ "$1" == "$PWD" ]]; then
        return 0
    fi
    if [ ! -d "$1" ]; then
        echo "$_TOX_ECHO_PRE: no such directory: $1"
        return 1
    fi
    if [ ! -r "$1" ]; then
        echo "$_TOX_ECHO_PRE: permission denied: $1"
        return 1
    fi
    cd "$1" >> /dev/null && echo "$_TOX_ECHO_PRE: switch to $(tput setaf 3)$1$(tput sgr0)"
}

# _tox_to
# $1 the base dir
# $2 the target dir
function _tox_to() {
    # if the target path is a absolute path, just try cd to the path.
    if [[ "$2" == /* ]]; then
        _tox_to_absolute "$2"
        return 0
    fi

    local p="$1/$2"
    local best

    if [ -d "$p" ]; then
        best="$p" 
    fi

    local results=()

    local i=0
    while read -r line; do
        if [[ ! "$line" == "$best" ]] && [[ ! "$line" == "$1" ]]; then
            i=$(expr ${i} + 1)
            results[$i]="$line"
        fi
    done < <(_tox_search "$1" "$2")

    if [[ "$best" == "" ]] && [ ${#results[@]} -eq 0 ]; then
        echo "$_TOX_ECHO_PRE: no matched dir: $2"
        return 1 
    fi

    if [[ "$best" == "" ]] && [ ${#results[@]} -eq 1 ]; then
        _tox_to_absolute "${results[1]}"
        return 0
    fi

    if [[ ! "$best" == "" ]] && [ ${#results[@]} -eq 0 ]; then
        _tox_to_absolute "$best" 
        return 0
    fi

    local PATH_L=${#1}
    local PREFIX_L=$(expr $PATH_L + 1)

    local tag=""

    if [[ ! $3 == "" ]]; then
        tag="$(tput setaf 4)$3$(tput sgr0)/" 
    fi

    if [[ ! "$best" == "" ]]; then
        echo "$(tput setaf 3)*:$(tput sgr0) $tag$(tput setaf 3)${best:${PREFIX_L}}$(tput sgr0)"
    fi

    i=0
    for item in ${results[@]}; do
        i=$(expr ${i} + 1)
        local index="$(tput setaf 1)$i$(tput sgr0): "
        local res=`echo $tag${results[$i]:${PREFIX_L}} | sed "s/$2/$(tput setaf 2)&$(tput sgr0)/g"`
        echo "$index$res"
    done

    printf "$(tput setaf 4)choose the dir with index: $(tput sgr0)(empty means the first one)"
    read -r index

    if [[ "$index" == "" ]]; then
        if [[ ! "$best" == "" ]]; then
            _tox_to_absolute "$best" 
            return 0
        fi
        _tox_to_absolute "${results[1]}"
        return 0
    fi

    if [ $index -le ${#results[@]} ]; then
        _tox_to_absolute "${results[$index]}"
        return 0
    fi

    echo "$_TOX_ECHO_PRE: no matching item"
    return 1
}

function tox() {

    _toxc_map_index "$PWD"

    if [ $# -eq 0 ]; then
        local nearest=`_toxc_point_nearest_point $PWD`
        if [[ "$nearest" == "" ]]; then
            echo "$_TOX_ECHO_PRE: current dir is not inside of any tox point"
            return 1
        fi
        _tox_to_absolute "$nearest"
        return 0
    fi

    if [[ "$1" == "-" ]]; then
        cd - >> /dev/null && echo "$_TOX_ECHO_PRE: switch to $(tput setaf 3)$PWD$(tput sgr0)"
        return 0
    fi

    local list=() 
    local nearest=""

    if [[ "$1" == @* ]]; then
        nearest=`_toxc_point_nearest_point "$PWD" "$1"`

        local i=0
        while read line; do
            if [[ ! "$line" == "$nearest" ]]; then
                i=$(expr ${i} + 1)
                list[$i]="$line"
            fi
        done < <(_toxc_map_seek "$1")

        if [[ "$nearest" == "" ]] && [ ${#list[@]} -eq 0 ]; then
            echo "$_TOX_ECHO_PRE: point $1 not exists"
            return 1
        fi

        local selected

        if [ ${#list[@]} -eq 0 ]; then
            # if the nearest point dir is the only result, cd to the neareast point dir
            if [[ ! "$nearest" == "" ]]; then
                selected="$nearest"
            fi
        elif [ ${#list[@]} -eq 1 ]; then
            # if there is only one result, cd to the dir directly
            if [[ "$nearest" == "" ]]; then
                selected="${list[1]}"
            fi
        fi

        if [[ "$selected" == "" ]]; then
            if [[ ! "$nearest" == "" ]]; then
                echo "$(tput setaf 3)*:$(tput sgr0) $tag$(tput setaf 3)$nearest$(tput sgr0)"
            fi

            local i=0

            for item in ${list[@]}; do
                i=$(expr ${i} + 1)
                local index="$(tput setaf 1)$i$(tput sgr0): "
                echo "$index: $item"
            done

            printf "$(tput setaf 4)choose the point with index: $(tput sgr0)(empty means the first one)"
            read -r index

            if [[ "$index" == "" ]]; then
                if [[ ! "$nearest" == "" ]]; then
                    selected="$nearest"
                else
                    selected="${list[1]}"
                fi
            else
                if [ $index -le ${#list[@]} ]; then
                    selected="${list[$index]}"
                else
                    echo "$_TOX_ECHO_PRE: no matching item"
                    return 1
                fi
            fi
        fi

        if [[ "$selected" == "" ]]; then
            return 1
        fi

        if [ $# -eq 1 ]; then
            _tox_to_absolute "$selected"
            return 0
        fi

        _tox_to "$selected" "$2" "$1"
    elif [[ "$1" == "." ]]; then
        _tox_to "$PWD" "$2"
    elif [[ "$1" == ".." ]]; then
        _tox_to "$(dirname $PWD)" "$2"
    else
        local nearest=`_toxc_point_nearest_point "$PWD"`
        _tox_to "$nearest" "$1"
    fi
}

#################################################################################
# toxe
#################################################################################
function _toxe_e() {
    local editor=`_toxc_point_item "$_TOX_HOME_RC" "editor"`
    if [[ "$1" == "" ]]; then
        eval "$editor"
    else
        eval "$editor $1"
    fi
}

function _toxe_search() {
    local D=`basename "$2"`
    local prune=""

    while read line; do
        if [[ "$line" == */* ]]; then
            prune+=" -type d -path $line -prune -o " 
        else
            prune+=" -type d -name $line -prune -o "
        fi
    done < <(_toxc_point_get_ignore "$1")

    while read -r line; do
        echo "$line"
    done < <(find "$1" `echo $prune` -type f -name "*$D*" -print)
}

function _toxe_o() {
    # if the target path is a absolute path, just try cd to the path.
    if [[ "$2" == /* ]]; then
        _toxe_e "$2"
        return 0
    fi

    local p="$1/$2"
    local best

    if [ -f "$p" ]; then
        best="$p" 
    fi

    local results=()

    local i=0
    while read -r line; do
        if [[ ! "$line" == "$best" ]] && [[ ! "$line" == "$1" ]]; then
            i=$(expr ${i} + 1)
            results[$i]="$line"
        fi
    done < <(_toxe_search "$1" "$2")

    if [[ "$best" == "" ]] && [ ${#results[@]} -eq 0 ]; then
        echo "$_TOX_ECHO_PRE: no matched file: $2"
        return 1 
    fi

    if [[ "$best" == "" ]] && [ ${#results[@]} -eq 1 ]; then
        _toxe_e "${results[1]}"
        return 0
    fi

    if [[ ! "$best" == "" ]] && [ ${#results[@]} -eq 0 ]; then
        _toxe_e "$best" 
        return 0
    fi

    local PATH_L=${#1}
    local PREFIX_L=$(expr $PATH_L + 1)

    local tag=""

    if [[ ! $3 == "" ]]; then
        tag="$(tput setaf 4)$3$(tput sgr0)/" 
    fi

    if [[ ! "$best" == "" ]]; then
        echo "$(tput setaf 3)*:$(tput sgr0) $tag$(tput setaf 3)${best:${PREFIX_L}}$(tput sgr0)"
    fi

    i=0
    for item in ${results[@]}; do
        i=$(expr ${i} + 1)
        local index="$(tput setaf 1)$i$(tput sgr0): "
        local res=`echo $tag${results[$i]:${PREFIX_L}} | sed "s/$2/$(tput setaf 2)&$(tput sgr0)/g"`
        echo "$index$res"
    done

    printf "$(tput setaf 4)choose the dir with index: $(tput sgr0)(empty means the first one)"
    read -r index

    if [[ "$index" == "" ]]; then
        if [[ ! "$best" == "" ]]; then
            _toxe_e "$best" 
            return 0
        fi
        _toxe_e "${results[1]}"
        return 0
    fi

    if [ $index -le ${#results[@]} ]; then
        _toxe_e "${results[$index]}"
        return 0
    fi

    echo "$_TOX_ECHO_PRE: no matching item"
    return 1
}

function toxe() {
    if [ $# -eq 0 ]; then
        _toxe_e
        return
    fi

    if [[ "$1" == @* ]]; then
        nearest=`_toxc_point_nearest_point "$PWD" "$1"`

        local i=0
        while read line; do
            if [[ ! "$line" == "$nearest" ]]; then
                i=$(expr ${i} + 1)
                list[$i]="$line"
            fi
        done < <(_toxc_map_seek "$1")

        if [[ "$nearest" == "" ]] && [ ${#list[@]} -eq 0 ]; then
            echo "$_TOX_ECHO_PRE: point $1 not exists"
            return 1
        fi

        local selected

        if [ ${#list[@]} -eq 0 ]; then
            # if the nearest point dir is the only result, cd to the neareast point dir
            if [[ ! "$nearest" == "" ]]; then
                selected="$nearest"
            fi
        elif [ ${#list[@]} -eq 1 ]; then
            # if there is only one result, cd to the dir directly
            if [[ "$nearest" == "" ]]; then
                selected="${list[1]}"
            fi
        fi

        if [[ "$selected" == "" ]]; then
            if [[ ! "$nearest" == "" ]]; then
                echo "$(tput setaf 3)*:$(tput sgr0) $tag$(tput setaf 3)$nearest$(tput sgr0)"
            fi

            local i=0

            for item in ${list[@]}; do
                i=$(expr ${i} + 1)
                local index="$(tput setaf 1)$i$(tput sgr0): "
                echo "$index: $item"
            done

            printf "$(tput setaf 4)choose the point with index: $(tput sgr0)(empty means the first one)"
            read -r index

            if [[ "$index" == "" ]]; then
                if [[ ! "$nearest" == "" ]]; then
                    selected="$nearest"
                else
                    selected="${list[1]}"
                fi
            else
                if [ $index -le ${#list[@]} ]; then
                    selected="${list[$index]}"
                else
                    echo "$_TOX_ECHO_PRE: no matching item"
                    return 1
                fi
            fi
        fi

        if [[ "$selected" == "" ]]; then
            return 1
        fi

        if [ $# -eq 1 ]; then
            _toxe_e "$selected"
            return 0
        fi

        _toxe_o "$selected" "$2" "$1"
    elif [[ "$1" == "." ]]; then
        _toxe_o "$PWD" "$2"
    elif [[ "$1" == ".." ]]; then
        _toxe_o "$(dirname $PWD)" "$2"
    else
        local nearest=`_toxc_point_nearest_point "$PWD"`
        _toxe_o "$nearest" "$1"
    fi
}
