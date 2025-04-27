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
mkfs.fat -F12 "$BOOTFS_IMAGE"

copy_item() {
    FILESYSTEM_ITEM=$1

    echo "==> $FILESYSTEM_ITEM"
    mcopy -i $BOOTFS_IMAGE $BOOTFS_MODULE/$FILESYSTEM_ITEM ::$FILESYSTEM_ITEM
}

FOLDER_ITEMS=$(ls "$BOOTFS_MODULE")
for FOLDER_ITEM in $FOLDER_ITEMS
do
    if [[ $FOLDER_ITEM == "makefs.sh" ]];
    then
        continue
    fi
    copy_item $FOLDER_ITEM
done

