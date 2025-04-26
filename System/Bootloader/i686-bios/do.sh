#!/bin/bash

# Ensure that the work-directory is the i686/ - direcetory
cd $(dirname $0)
I686_PATH=$(pwd)

if [[ "$#" == "0" ]];
then
    echo "Usage:   $ $0 <action> [flags]"
    echo "Example: $ $0 help"
    exit -1
fi

display_help() {
    # If the general help-page is meant
    if [[ "$#" == "0" ]];
    then
        cat "$I686_PATH/assets/help-texts/main.txt"
        return
    fi
}

case $1 in
    "b" | "build")
        $I686_PATH/src-sh/build.sh ${@:2:"$#"}
        ;;
    "q" | "qemu")
        $I686_PATH/src-sh/run-qemu.sh ${@:2:"$#"}
        ;;
    "fs" | "make-bootfs")
        $I686_PATH/modules/bootfs/makefs.sh ${@:2:$#}
        ;;
    "h" | "help")
        display_help ${@:2:"$#"}
        ;;
    *)
        echo "Unknown action. Try:"
        echo "$ $0 help"
        ;;
esac

