#!/bin/bash

cd $(dirname $0)/../..
I686_PATH=$(pwd)

if [[ -d "$I686_PATH/.tests/builds" ]];
then
    rm -r $I686_PATH/.tests/builds
fi

if [[ -d "$I686_PATH/.tests/instances" ]];
then
    rm -r $I686_PATH/.tests/instances
fi
