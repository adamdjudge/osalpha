; The OS Alpha Kernel
; Copyright (C) 2021 Adam Judge
;
; File: floppy.asm
; Last modified: 25 May 2020
; Description: Floppy driver subroutines

; Variables
sectors_per_track  dw 0
num_sides          dw 0

; Read sectors from floppy into buffer
; Params: AX = start LBA, ES:BX = buffer, CX = number of LBAs
; Return: Buffer is filled with data, or carry set on error
fd_read:
    push ax
    push bx
    push cx
    call _read_sector
    pop cx
    pop bx
    pop ax
    jc .end_read
    add ax, 1
    add bx, 512
    loop fd_read
.end_read:
    ret

; ==============================================================================
; INTERNAL SUBROUTINES
; ==============================================================================

; Reset the floppy controller
; Params: None
; Return: Carry set on error
_reset_floppy:
    push ax
    push dx
    mov ax, 0
    mov dl, 0
    stc
    int 0x13
    pop dx
    pop ax
    ret

; Load one sector from floppy into buffer
; Params: AX = start LBA, ES:BX = buffer
; Return: Buffer is filled with data, or carry set on error
_read_sector:
    mov byte [.attempts_remaining], 4
    call _lba_to_hts
    mov ah, 2
    mov al, 1
    pusha
.try_read:
    dec byte [.attempts_remaining]
    jz .read_give_up
    popa
    pusha
    stc
    int 0x13
    jc .do_reset
    popa
    ret
.do_reset:
    call _reset_floppy
    jnc .try_read
.read_give_up:
    popa
    stc
    ret
.attempts_remaining:
    db 0

; Calculate head, track, and sector for BIOS disk routines
; Params: AX = logical block
; Return: Registers set to BIOS parameters
_lba_to_hts:
    push bx
    push ax
    mov bx, ax

    ; Get sector
    mov dx, 0
    div word [sectors_per_track]
    add dl, 1
    mov cl, dl
    mov ax, bx

    ; Get head and track
    mov dx, 0
    div word [sectors_per_track]
    mov dx, 0
    div word [num_sides]
    mov dh, dl
    mov ch, al

    pop ax
    pop bx
    mov dl, 0
    ret
