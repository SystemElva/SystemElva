#!/bin/bash

cd $(dirname $0)/../..
I686_PATH=$(pwd)

# Script Dependencies

INI="$I686_PATH/src-sh/ini.sh"



repeat_string() {
    STRING=$1
    NUM_REPETITIONS=$2

    REPETITION=0
    while [[ $REPETITION -le $NUM_REPETITIONS ]];
    do
        printf "$STRING"
        ((REPETITION++))
    done
}

TEST_BUILD_LIST=$(ls $I686_PATH/.tests/builds | sort --reverse)

echo "| ----- | ------------------------------------------------- |"
echo "| Index | Label                                             |"
echo "| ----- | ------------------------------------------------- |"

BUILD_INDEX=0
for TEST_BUILD_ITEM in $TEST_BUILD_LIST
do
    TEST_BUILD_PATH=$I686_PATH/.tests/builds/$TEST_BUILD_ITEM
    TEST_BUILD_LABEL=$($INI -g Build:Label $TEST_BUILD_PATH/build_config.ini)

    ((SPACES_AFTER_INDEX=5-${#BUILD_INDEX}))
    ((SPACES_AFTER_LABEL=48-${#TEST_BUILD_LABEL}))

    printf "| $BUILD_INDEX"
    repeat_string " " $SPACES_AFTER_INDEX

    printf "| $TEST_BUILD_LABEL"
    repeat_string " " $SPACES_AFTER_LABEL

    echo " |"

    ((BUILD_INDEX++))
done
echo "| ----- | ------------------------------------------------- |"
