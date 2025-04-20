#!/bin/bash

cd $(dirname $0)/..
I686_PATH=$(pwd)

IMAGE_NAME=$(ls $I686_PATH/.out | grep ".img\$" | sort | tail -n1)

qemu-system-i386 \
    -m 32M -enable-kvm \
    -d guest_errors -qmp unix:qmp.socket,server,nowait \
    $I686_PATH/.out/$IMAGE_NAME

