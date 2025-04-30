
bits 16
org 0xa000
main:
.setup_stack:
    mov ebx, 0x800
    mov ss, ebx
    mov ebp, 0x2000
    mov esp, ebp

    sub esp, 256
    mov esi, esp

.clear_display:
    mov ah, 0x00
    mov al, 0x03
    int 0x10

.setup_string_loop:
    xor     ecx,                ecx

.string_loop:
    mov     edx,                ecx
    shl     edx,                3
    add     edx,                4 ; Go to string pointer
    mov     ebx,                [text_pointers + edx]

    ; If this is the last entry, all was successfull.
    cmp     ebx,                0
    jne     .continue


    push ebp
    mov ebp, esp
    push word BACKGROUND_GREEN
    call set_background
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword status_codes.correct
    push dword 36
    push dword 12
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    cli
    hlt

.continue:
    push    ebp
    mov     ebp,                esp
    push    ebx
    call    strlen
    mov     esp,                ebp
    pop     ebp

    mov     edx,                ecx
    shl     edx,                3
    mov     ebx,                [text_pointers + edx]

    inc     ecx
    cmp     ebx,                eax
    je      .string_loop


    push ebp
    mov ebp, esp
    push word BACKGROUND_RED
    call set_background
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword status_codes.invalid
    push dword 36
    push dword 12
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    cli
    hlt



status_codes:
.invalid:
    db "Invalid", 0x00
.correct:
    db "Correct", 0x00

%include "utility.asm"
%include "generated_test_cases.asm"
