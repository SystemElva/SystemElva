#!/bin/bash

cd $(dirname $0)/..
I686_PATH=$(pwd)

if [[ -d "$I686_PATH/.build/modules" ]];
then
    rm -r $I686_PATH/.build/modules
fi

if [[ -d "$I686_PATH/.out" ]];
then
    if [[ $(ls "$I686_PATH/.out") != "" ]];
    then
        rm $I686_PATH/.out/*.img
    fi
fi