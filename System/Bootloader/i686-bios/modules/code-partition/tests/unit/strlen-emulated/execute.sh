#!/bin/bash

LOG_PATH=$1

./objects/object.elf

EXIT_CODE=$?

printf "Exit Code: $EXIT_CODE" >> $LOG_PATH

if [[ $EXIT_CODE == 0 ]];
then
    printf " - Success!" >> $LOG_PATH
fi
echo " " >> $LOG_PATH

