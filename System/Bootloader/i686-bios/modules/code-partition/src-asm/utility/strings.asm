
; strlen:
;   Count number of chars in string up to a maximum.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     1.  U32       maximum
;     0.  Ptr32     string
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]: Length of string
strlen:
.prolog:
    pushad

.setup_counter_loop:
    xor ecx, ecx

.counter_loop:
    mov eax, [ebp - 4]
    add eax, ecx
    cmp [eax], byte 0x00
    je .epilog

    cmp ecx, [ebp - 8]
    jae .epilog

    inc ecx
    jmp .counter_loop

.epilog:
    mov [esp + 28], ecx
    popad
    ret



; string_equals_ignore_case:
;
; Arguments:
;   [FURTHEST FROM EBP]
;     1.  ptr32<u8>                     string_2
;     0.  ptr32<u8>                     string_1
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    1 if equal, 0 if not equal
string_equals_ignore_case:
.prolog:
    pushad

.setup_checker_loop:
    xor ecx, ecx

.checker_loop:
    mov ebx, [ebp - 4]
    add ebx, ecx
    mov al, [ebx]

    cmp al, byte 'a'
    jb .string1_char_not_lowercase
    
    cmp al, byte 'z'
    ja .string1_char_not_lowercase
    
    sub al, 32

.string1_char_not_lowercase:
    mov ebx, [ebp - 8]
    add ebx, ecx
    mov ah, [ebx]

    cmp ah, byte 'a'
    jb .string2_char_not_lowercase
    
    cmp ah, byte 'z'
    ja .string2_char_not_lowercase
    
    sub ah, 32

.string2_char_not_lowercase:
    cmp al, ah
    jne .not_equal

    inc ecx
    cmp al, 0x00
    jne .checker_loop

    popad
    mov eax, 1
    ret

.not_equal:
    popad
    xor eax, eax
    ret



; memory_equals_ignore_case:
;
; Arguments:
;   [FURTHEST FROM EBP]
;     2.  u32                           len_strings
;     1.  ptr32<u8>                     string_2
;     0.  ptr32<u8>                     string_1
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    1 if equal, 0 if not equal
memory_equals_ignore_case:
.prolog:
    pushad

.setup_checker_loop:
    xor ecx, ecx

.checker_loop:
    mov ebx, [ebp - 4]
    add ebx, ecx
    mov al, [ebx]

    cmp al, byte 'a'
    jb .string1_char_not_lowercase
    
    cmp al, byte 'z'
    ja .string1_char_not_lowercase
    
    sub al, 32

.string1_char_not_lowercase:
    mov ebx, [ebp - 8]
    add ebx, ecx
    mov ah, [ebx]

    cmp ah, byte 'a'
    jb .string2_char_not_lowercase
    
    cmp ah, byte 'z'
    ja .string2_char_not_lowercase
    
    sub ah, 32

.string2_char_not_lowercase:
    cmp al, ah
    jne .not_equal

    inc ecx
    cmp ecx, [ebp - 12]
    jb .checker_loop

    popad
    mov eax, 1
    ret

.not_equal:
    popad
    xor eax, eax
    ret

