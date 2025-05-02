
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

.reset_display:
    ; Reset display
    mov ah, 0x00
    mov al, 0x03
    int 0x10

.run_tests:
    push ebp
    mov ebp, esp
    call test_short_file_names
    mov esp, ebp
    pop ebp
    cli

    push ebp
    mov ebp, esp
    call test_long_file_names
    mov esp, ebp
    pop ebp
    cli

.success:
    push ebp
    mov ebp, esp
    push word BACKGROUND_GREEN
    call set_background
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword status_strings.success
    push dword 5
    push dword 11
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    cli
    hlt


; test_short_file_names:
;
;
test_short_file_names:
.prolog:
    pushad

.setup_file_name_loop:
    xor ecx, ecx

.file_name_loop:
    mov ebx, ecx
    shl ebx, 2
    add ebx, short_file_name_pointers
    mov eax, [ebx]
    cmp eax, 0
    je .success

    push ebp
    mov ebp, esp
    push eax
    call fat12_is_long_file_name
    mov esp, ebp
    pop ebp

    cmp eax, 1
    je .failure

    inc ecx
    jmp .file_name_loop

.success:
    popad
    ret

.failure:
    push ebp
    mov ebp, esp
    push word BACKGROUND_RED
    call set_background
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword status_strings.falsely_long
    push dword 5
    push dword 11
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword [ebx]
    push dword 5
    push dword 13
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    cli
    hlt



; test_long_file_names:
;
;
test_long_file_names:
.prolog:
    pushad

.setup_file_name_loop:
    xor ecx, ecx

.file_name_loop:
    mov ebx, ecx
    shl ebx, 2
    add ebx, long_file_name_pointers
    mov eax, [ebx]
    cmp eax, 0
    je .success

    push ebp
    mov ebp, esp
    push eax
    call fat12_is_long_file_name
    mov esp, ebp
    pop ebp

    cmp eax, 0
    je .failure

    inc ecx
    jmp .file_name_loop

.success:
    popad
    ret

.failure:
    push ebp
    mov ebp, esp
    push word BACKGROUND_RED
    call set_background
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword status_strings.falsely_short
    push dword 5
    push dword 11
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword [ebx]
    push dword 5
    push dword 13
    push word FOREGROUND_WHITE
    call write_text
    mov esp, ebp
    pop ebp

    cli
    hlt



status_strings:
.falsely_short:
    db "Long file name falsely not identified as long:", 0x00

.falsely_long:
    db "Short file name falsely identified as long:", 0x00

.success:
    db "Success!", 0x00

%include "generated_short_file_names.asm"
%include "generated_long_file_names.asm"

%include "all.asm"
