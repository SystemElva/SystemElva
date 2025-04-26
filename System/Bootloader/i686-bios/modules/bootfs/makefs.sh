#!/bin/bash

cd $(dirname $0)
BOOTFS_MODULE=$(pwd)

cd ../../
I686_PATH=$(pwd)

BOOTFS_BUILD=$I686_PATH/.build/modules/bootfs
mkdir -p $BOOTFS_BUILD
rm $BOOTFS_BUILD/*

BOOTFS_IMAGE=$BOOTFS_BUILD/fat12.img
((PARTITION_SIZE=1024*512))
truncate $BOOTFS_IMAGE --size $PARTITION_SIZE
mkfs.fat -F12 $BOOTFS_IMAGE

copy_item() {
    FILESYSTEM_ITEM=$1

    echo $FILESYSTEM_ITEM
    mcopy -i $BOOTFS_IMAGE $BOOTFS_MODULE/$FILESYSTEM_ITEM ::$FILESYSTEM_ITEM
}

((LEN_FIND_PREFIX=${#BOOTFS_MODULE}+1))
FOLDER_ITEMS=$(find $BOOTFS_MODULE -mindepth 1)
for FOLDER_ITEM in $FOLDER_ITEMS
do
    LEN_RAW_FOLDER_ITEM=${#FOLDER_ITEM}
    FOLDER_ITEM=${FOLDER_ITEM:LEN_FIND_PREFIX:$LEN_RAW_FOLDER_ITEM}
    if [[ $FOLDER_ITEM == "makefs.sh" ]];
    then
        continue
    fi
    copy_item $FOLDER_ITEM
done

