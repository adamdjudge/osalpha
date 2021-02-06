; OS Alpha floppy bootloader
; Copyright (C) 2021 Adam Judge
;
; File: bootload.asm
; Last modified: 25 May 2020
; Description: Loads OS Alpha kernel from disk
; Note: Based heavily on the MikeOS bootloader

    BITS 16

    jmp short start
    nop

; Disk descriptor table for 1.44 MB 3.5" diskette
descriptor:
    oem_label            db "OS ALPHA"
    bytes_per_sector     dw 512
    sectors_per_clustor  db 1
    boot_reserved        dw 1
    num_fats             db 2
    num_root_dir_entries dw 224
    num_logical_sectors  dw 2880
    medium_byte          db 0xf0
    sectors_per_fat      dw 9
    sectors_per_track    dw 18
    num_sides            dw 2
    num_hidden_sectors   dd 0
    num_large_sectors    dd 0
    drive_number         dw 0
    signature            db 41
    volume_id            dd 0
    volume_label         db "OS ALPHA   "
    file_system          db "FAT12   "

; Start bootloader
start:
    ; Setup 4k stack above 8k disk buffer
    mov ax, ((0x7C00 + 512 + 8192) >> 4)
    cli
    mov ss, ax
    mov sp, 4096
    sti

    ; Set data and extra segments to where we are
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax

    ; TODO: Check if drive number is not 0

    ; Load root directory from disk
    ; Start of root dir = boot_reserved + num_fats * sectors_per_fat = block 19
    ; Root dir blocks = num_root_dir_entries * 32 bytes / bytes_per_sector = 14
    mov ax, 19
    mov cl, 14
    mov bx, buffer
    call read_floppy

    ; Search through all file entries for kernel
    mov di, buffer
    mov cx, word [num_root_dir_entries]
    mov ax, 32

next_root_entry:
    xchg cx, dx

    ; Compare name of current entry to kernel filename
    mov si, kernel_name
    mov cx, 11
    rep cmpsb
    je found_file

    ; Next entry
    mov di, buffer
    add di, ax
    add ax, 32
    xchg cx, dx
    loop next_root_entry

    ; Error if kernel not found
    mov si, not_found
    call print
    jmp reboot

found_file:
    ; Get start LBA of file entry
    mov ax, word [es:di+15]
    mov word [cluster], ax

    ; Load FAT
    mov ax, 1
    mov cl, byte [sectors_per_fat]
    mov bx, buffer
    call read_floppy

    ; Load kernel into segment 0x1000
    mov ax, 0x1000
    mov es, ax

load_file_sector:
    mov ax, word [cluster]
    add ax, 31
    mov bx, word [pointer]
    mov cl, 1
    call read_floppy

get_next_cluster:
    mov ax, [cluster]
    mov dx, 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx

    mov si, buffer
    add si, ax
    mov ax, word [ds:si]

    or dx, dx
    jz even

odd:
    shr ax, 4
    jmp short check_cluster

even:
    and ax, 0x0fff

check_cluster:
    mov word [cluster], ax

    cmp ax, 0x0ff8
    jae end_bootloader

    add word [pointer], 512
    jmp load_file_sector

end_bootloader:
    jmp 0x1000:0x0000

; ==============================================================================
; BOOTLOADER SUBROUTINES
; ==============================================================================

; Print a null-terminated string
; Params: SI = String pointer
; Return: None
print:
    pusha
    mov ah, 0xE
.repeat:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp short .repeat
.done:
    popa
    ret

; Load sectors from floppy into buffer
; Params: AX = start LBA, CL = num LBAs, ES:BX = buffer
; Return: Buffer is filled with data
read_floppy:
    push cx
    call lba_to_hts
    pop ax
    mov ah, 2
    pusha
.try_read:
    popa
    pusha
    stc
    int 0x13
    jc .reset
    popa
    ret
.reset:
    call reset_floppy
    jnc .try_read
    mov si, disk_err
    call print
    jmp reboot

; Calculate head, track, and sector for BIOS disk routines
; Params: AX = logical block
; Return: Registers set to BIOS parameters
lba_to_hts:
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

; Reset the floppy controller
; Params: None
; Return: Carry set on error
reset_floppy:
    push ax
    push dx
    mov ax, 0
    mov dl, 0
    stc
    int 0x13
    pop dx
    pop ax
    ret

; Reboots the system
; Params: None
; Return: Doesn't
reboot:
    mov si, key_prompt
    call print
    mov ax, 0
    int 0x16
    mov ax, 0
    int 0x19

; ==============================================================================
; STRINGS AND VARIABLES
; ==============================================================================

kernel_name  db "KERNEL  BIN"
disk_err     db "Disk error.", 0
not_found    db "Kernel not found.", 0
key_prompt   db " Press any key to reboot...", 0xD, 0xA, 0

cluster      dw 0
pointer      dw 0

; ==============================================================================
; END OF BOOT SECTOR
; ==============================================================================

    times 510-($-$$) db 0
    dw 0xAA55

buffer:
