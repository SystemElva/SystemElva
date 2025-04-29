#!/bin/bash

INVOCATION_PATH=$(pwd)

cd $(dirname $0)
CODE_PARTITION=$(pwd)/..
TEST_FOLDER=$CODE_PARTITION/tests

cd $CODE_PARTITION/../..
I686_BIOS_FOLDER=$(pwd)
BUILD_FOLDER=$I686_BIOS_FOLDER/.build/modules/

if [[ $# != 1 ]];
then
    echo "Usage: $0 <ini-parser>"
    exit 1
fi

INI=$1
if [[ ${INI:0:1} != "/" ]];
then
    INI=$INVOCATION_PATH/$1
fi

if [[ ! -f "$INI" ]];
then
    echo "Coulnn't find INI-parser at $INI!"
    exit 1
fi

build_bootable_test() {
    TEST_PATH=$1
    TEST_CONFIG="$TEST_PATH/test.ini"

    TEST_NAME=$($INI --get General:Name $TEST_CONFIG)
    TEST_VERSION=$($INI --get General:Version $TEST_CONFIG)

    echo "Building Test: $TEST_NAME, version $TEST_VERSION"

    SOURCE=$($INI --get "General:Source" $TEST_CONFIG)
    SOURCE=${SOURCE/"{code-partition}"/$CODE_PARTITION}
    SOURCE=${SOURCE/"{test}"/$TEST_PATH}

    mkdir -p $BUILD_FOLDER/code-partition/tests/
    nasm -o $BUILD_FOLDER/code-partition/tests/$TEST_NAME.bin \
        $SOURCE -i $CODE_PARTITION/src-asm

    mkdir -p $I686_BIOS_FOLDER/.tests/code-partition
    HD_DISKETTE_BYTES=$((2880*512)) # 2880 sectors of 512 bytes each
    OUTPUT_FILE=$I686_BIOS_FOLDER/.tests/code-partition/$TEST_NAME.img

    truncate $OUTPUT_FILE --size $HD_DISKETTE_BYTES

    dd \
        conv=notrunc cbs=512 \
        if=$BUILD_FOLDER/bootsector/object.bin \
        of=$OUTPUT_FILE

    dd \
        conv=notrunc oseek=1 cbs=512 \
        if=$BUILD_FOLDER/code-partition/tests/$TEST_NAME.bin \
        of=$OUTPUT_FILE

    dd \
        conv=notrunc oseek=64 cbs=512 \
        if=$I686_BIOS_FOLDER/.build/modules/bootfs/fat12.img \
        of=$OUTPUT_FILE
}

build_test() {
    TEST_PATH=$1
    TEST_CONFIG="$TEST_PATH/test.ini"

    RUN_ENVIRONMENT=$($INI --get General:Environment $TEST_CONFIG)
    if [[ $RUN_ENVIRONMENT == "BOOTABLE" ]];
    then
        build_bootable_test $TEST_PATH
    fi
}

for TEST_ITEM in $(ls $TEST_FOLDER)
do
    build_test $TEST_FOLDER/$TEST_ITEM
done

