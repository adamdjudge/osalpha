#!/bin/bash

VERSION=0.0.1

if [ "$1" == "clean" ]; then
    rm *.bin
    rm kernel/build.asm
    rm -f osalpha.img
    exit
fi

echo "version:" > kernel/build.asm
echo "    db \"Kernel version: $VERSION\", 0xD, 0xA" >> kernel/build.asm
echo "    db \"Compiled: $(date)\", 0xD, 0xA, 0" >> kernel/build.asm

nasm bootload.asm -o bootload.bin

cd kernel
nasm main.asm -o kernel.bin
cd ..
mv kernel/kernel.bin .

if [ "$1" == "disk" ]; then
    mkfs.msdos -C osalpha.img 1440
    dd if=bootload.bin of=osalpha.img conv=notrunc
    sudo mkdir /mnt/floppy
    sudo mount -o loop osalpha.img /mnt/floppy

    sudo cp kernel.bin /mnt/floppy/

    sudo umount /mnt/floppy
    sudo rm -r /mnt/floppy
fi
