#!/bin/bash

cd $(dirname $0)/..
I686_PATH=$(pwd)

$I686_PATH/src-sh/tests/cleanup.sh
$I686_PATH/src-sh/cleanup.sh
