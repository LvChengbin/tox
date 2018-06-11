#!/bin/bash

. $(dirname "$0")/toxv.sh

function toxc() {
    if [ $# -eq 0 ]; then
        echo "tox: version: $_TOX_VERSION"
        $(dirname "$0")/c/c.sh "$_TOX_DIR" "$_TOX_MAP_FILE" "$_TOX_HOME/$_TOX_RC"
        if [ ! -f $PWD/$_TOX_RC ]; then
            echo "current dir is not a tox point" 
        else
            echo "current point: "
        fi
        return
    fi

    case $1 in
        init)

            printf "point name: (empty)"
            read -r point

            if ! [[ point == @* ]]; then
                point="@$point"
            fi

            # to create RC file in current directory
            $(dirname "$0")/c/init.sh $PWD/$_TOX_RC $point


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
            $(dirname "$0")/map/read.sh $_TOX_MAP_FILE
            ;;
        *)
            echo "tox: unknow option $1"
            ;;
    esac
}
