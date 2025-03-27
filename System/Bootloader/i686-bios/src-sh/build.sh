#!/bin/env sh

cd $(dirname $0)/..
I686_PATH=$(pwd)

BOOTSECTOR_OBJECTS="$I686_PATH/.build/modules/bootsector"
CODE_PARTITION_OBJECTS="$I686_PATH/.build/modules/code-partition"

BOOTSECTOR_SOURCES="$I686_PATH/modules/bootsector/src-asm"
CODE_PARTITION_SOURCES="$I686_PATH/modules/code-partition/src-asm"

OUTPUT_DIRECTORY=$I686_PATH/.out

EXECUTION_TIME=$(date "+%Y-%m-%d.%H-%M-%S")

# Create the objects folder, in case it hasn't been created before
mkdir -p $BOOTSECTOR_OBJECTS
mkdir -p $CODE_PARTITION_OBJECTS
mkdir -p $OUTPUT_DIRECTORY

# Make sure that no old object-files are in the objects-folder
rm -f $BOOTSECTOR_OBJECTS/*.o
rm -f $CODE_PARTITION_OBJECTS/*.o

nasm -o $BOOTSECTOR_OBJECTS/object.bin \
    $BOOTSECTOR_SOURCES/bootsector.asm \
    -i $BOOTSECTOR_SOURCES

nasm -o $CODE_PARTITION_OBJECTS/object.bin \
    $CODE_PARTITION_SOURCES/main.asm \
    -i $CODE_PARTITION_SOURCES

OUTPUT_FILE=$OUTPUT_DIRECTORY/elvaboot-$EXECUTION_TIME.img

HD_DISKETTE_BYTES=$((2880*512)) # 2880 sectors of 512 bytes each
truncate $OUTPUT_FILE --size=$HD_DISKETTE_BYTES

dd conv=notrunc cbs=512 if=$BOOTSECTOR_OBJECTS/object.bin of=$OUTPUT_FILE
dd conv=notrunc cbs=512 if=$CODE_PARTITION_OBJECTS/object.bin of=$OUTPUT_FILE oseek=1

