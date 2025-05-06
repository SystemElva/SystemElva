#!/bin/bash

cd $(dirname $0)

cd ../
I686_PATH=$(pwd)

BOOTFS_BUILD=$I686_PATH/.build/modules/bootfs
BOOTFS_CONTENT=$I686_PATH/modules/bootfs/content
mkdir -p $BOOTFS_BUILD

if [[ $(ls "$BOOTFS_BUILD") != "" ]];
then
    rm $BOOTFS_BUILD/fat12.img
fi

BOOTFS_IMAGE=$BOOTFS_BUILD/fat12.img
((PARTITION_SIZE=1024*512))
truncate $BOOTFS_IMAGE --size $PARTITION_SIZE
mkfs.fat -F12 "$BOOTFS_IMAGE" >> /dev/null

copy_item() {
    FILESYSTEM_ITEM=$1

    echo "==> $FILESYSTEM_ITEM"
    mcopy -s -i $BOOTFS_IMAGE $BOOTFS_CONTENT/$FILESYSTEM_ITEM ::$FILESYSTEM_ITEM
}

echo "Copying files..."

FOLDER_ITEMS=$(ls "$BOOTFS_CONTENT")
for FOLDER_ITEM in $FOLDER_ITEMS
do
    copy_item $FOLDER_ITEM
done
