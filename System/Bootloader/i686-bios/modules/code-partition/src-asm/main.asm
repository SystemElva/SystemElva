
; DO NOT INCLUDE OTHER FILES HERE; DO THAT AT THE BOTTOM OF THIS FILE

bits 16
org 0xa000

stage2_start:
.setup_stack:
    mov ebx, 0x800
    mov ss, ebx
    mov ebp, 0x2000
    mov esp, ebp

    sub esp, 256
    mov esi, esp

    ; Save the origin disk identifier
    mov [esi], dx

    ; Reset display
    mov ah, 0x00
    mov al, 0x03
    int 0x10

.load_partition:
    mov eax, esi
    add eax, (256 - 32)

    push ebp
    mov ebp, esp
    push eax
    push word [esi]
    push word 1
    call disk_open_partition
    mov esp, ebp
    pop ebp

    mov ebx, esi
    add ebx, (256 - 64)

    push dword text.unimplemented
    jmp crash_with_text



; crash_with_text:
;   @todo
; 
; Arguments:
;   [FURTEHST FROM STACK-TOP]
;     0.  Ptr32     string_pointer
;   [NEAREST TO STACK-TOP]
; 
; Return Value:
;   N/A
crash_with_text:
    ; Reset/Clear display
    mov ah, 0x00
    mov al, 0x03
    int 0x10

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
%include "disk.asm"

