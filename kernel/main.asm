; The OS Alpha Kernel
; Copyright (C) 2021 Adam Judge
;
; File: main.asm
; Last modified: 25 May 2020
; Description: Start kernel execution

    BITS 16

    ; Constants
    %define segment           0x1000
    %define disk_buffer       buffer
    %define disk_buffer_size  8192

    ; Go to start of kernel
    jmp short start

    ; 0x1000:0x0002 - OS API entry point
    ;jmp api_entry

start:
    ; Setup stack and segments
    cli
    mov ax, segment
    mov ds, ax
    mov ss, ax
    mov sp, 0xffff
    sti

    ; Set some floppy-related variables using boot sector
    mov ax, 0x07c0
    mov es, ax
    mov ax, word [es:24]
    mov word [sectors_per_track], ax
    mov ax, word [es:26]
    mov word [num_sides], ax
    mov ax, segment
    mov es, ax

    ; Print welcome message
    mov si, welcome
    call print
    mov si, version
    call print
    call newln

    ; Test stuff
    mov ax, 19
    mov cx, 14
    mov bx, disk_buffer
    call fd_read

    mov si, disk_buffer
    mov cx, 64
char_loop:
    lodsb
    call putc
    loop char_loop

hang:
    jmp hang

; ==============================================================================
; STRINGS
; ==============================================================================

welcome db "Welcome to OS Alpha!", 0xD, 0xA, 0

; ==============================================================================
; END OF MAIN CODE
; ==============================================================================

    %include "build.asm"
    %include "console.asm"
    %include "floppy.asm"

buffer:
