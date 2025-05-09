
; crash:
;   Write the text that was last pushed onto the stack and then halt indefinitely.
;   NOTE: This function only works when JMP'd to, not when being CALL'd.
; 
; Arguments:
;   [FURTEHST FROM STACK-TOP]
;     0.  Ptr32     string_pointer
;   [NEAREST TO STACK-TOP]
; 
; Return Value:
;   N/A
crash:
    ; Reset/Clear display
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    mov ebx, [ebp - 4]

    push ebp
    mov ebp, esp
    push ebx
    push dword 80
    call strlen
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
