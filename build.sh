#!/bin/bash

VERSION=0.0.1

echo "version:" > kernel/build.asm
echo "    db \"Kernel version: $VERSION\", 0xD, 0xA" >> kernel/build.asm
echo "    db \"Compiled: $(date)\", 0xD, 0xA, 0" >> kernel/build.asm

nasm bootload.asm -o bootload.bin

cd kernel
nasm main.asm -o kernel.bin
cd ..
mv kernel/kernel.bin .
