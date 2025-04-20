
; DO NOT INCLUDE OTHER FILES HERE; DO THAT AT THE BOTTOM OF THIS FILE

bits 16
org 0xa000
stage2_start:
.setup_stack:
    mov ebx, 0x800
    mov ss, ebx
    mov ebp, 0x2000
    mov esp, ebp

    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Save the origin disk identifier
    push ax

.find_kernel:

    push dword text.unimplemented
    jmp crash_with_text

    cli
    hlt

; write_text:
;   Put a NUL-terminated character string onto the display
;   using the BIOS functions at INT 0x10.
; 
; Arguments:
;   [FURTHEST FROM EBP]
;     0.  U16       color_code (Only lower 8 bits used)
;  [NEAREST TO EBP]
; 
; Return Value:
;   N/A
crash_with_text:
    pop ebx

    push ebp
    mov ebp, esp
    push ebx
    push dword 80
    call string_length
    mov esp, ebp
    pop ebp

    ; Subtract half the string's size from half the screen's width (80 / 2 = 40)
    ; to get the start position of the error message.
    shr eax, 1
    mov edx, 40
    sub edx, eax

    push ebp
    mov ebp, esp
    push ebx
    push dword edx
    push dword 12
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push word BACKGROUND_RED
    call set_background
    mov esp, ebp
    pop ebp

    cli
    hlt

text:
.unimplemented:
    db "Unimplemented Feature!", 0x00

%include "utility.asm"

