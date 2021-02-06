; The OS Alpha Kernel
; Copyright (C) 2021 Adam Judge
;
; File: console.asm
; Last modified: 25 May 2020
; Description: Text display and graphical subroutines

; Print the character in AL to the screen
; Params: AL = character
; Return: None
putc:
    mov ah, 0xE
    int 0x10
    ret

; Print a null-terminated string
; Params: SI = String pointer
; Return: None
print:
    mov ah, 0xE
.repeat:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp short .repeat
.done:
    ret

; Go to the start of the next line
; Params: None
; Return: None
newln:
    pusha
    mov ah, 0xE
    mov al, 0xD
    int 0x10
    mov al, 0xA
    int 0x10
    popa
    ret
