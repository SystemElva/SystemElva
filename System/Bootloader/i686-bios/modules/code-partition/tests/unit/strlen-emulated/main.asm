
global _start

_start:

.setup_string_loop:
    xor     ecx,                ecx

.string_loop:
    mov     edx,                ecx
    shl     edx,                3
    add     edx,                4           ; Go to string pointer
    mov     ebx,                [text_pointers + edx]

    ; If this is the last entry, all was successfull.
    cmp     ebx,                0
    jne     .continue
    
    ; Success
    mov     eax,                0x01        ; Syscall: Exit
    mov     ebx,                0           ; Success
    syscall

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

    ; Success
    mov     eax,                0x01        ; Syscall: Exit
    mov     ebx,                ecx         ; Failure
    syscall

%include "utility/strings.asm"
%include "generated_test_cases.asm"
