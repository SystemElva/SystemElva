
; path_search_element:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  U32       element_index
;     1.  U32       len_string
;     0.  Ptr32     string
;   [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    element_offset or 0xffffffff if not found
path_search_element:
.prolog:
    pushad

.setup_copy_loop:
    mov edx, [ebp - 8]
    mov ebx, [ebp - 4]
    xor ecx, ecx

    xor edi, edi

.copy_loop:
    cmp ecx, edx
    jae .string_exceeded

    mov al, [ebx + ecx]
    cmp al, '/'
    jne .continue_searching

    cmp edi, [ebp - 12]
    jae .element_found

    inc edi
    jmp .continue_searching

.element_found:
    inc ecx ; Don't include the slash
    mov [esp + 28], ecx
    popad
    ret

.continue_searching:
    inc ecx
    jmp .copy_loop

.string_exceeded:
    popad
    mov eax, 0xffffffff
    ret


; path_copy_element:
;   
;
; Arguments (5):
;   [FURTHEST FROM EBP]
;     4.  U32       element_index
;     3.  U32       len_buffer
;     2.  Ptr32     buffer
;     1.  U32       len_string
;     0.  Ptr32     string
;   [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    len_element_name or 0xffffffff on error
path_copy_element:
.prolog:
    pushad
    sub esp, 16
    mov esi, es

    mov eax, [ebp - 4]
    mov [esi], eax

    mov eax, [ebp - 8]
    mov [esi + 4], eax

    mov eax, [ebp - 20]
    mov [esi + 8], eax

.find_start:
    push ebp
    mov ebp, esp
    push dword [esi]
    push dword [esi + 4]
    push dword [esi + 8]
    call path_search_element
    mov esp, ebp
    pop ebp

    mov [esi + 12], eax

    ; If no element with that index could be found
    ; -> Return the error status.
    cmp eax, 0xffffffff
    jne .setup_copy_loop
    mov [esp + 28], eax
    popad
    ret

.setup_copy_loop:
    xor ecx, ecx        ; Input Offset

.copy_loop:
    mov ebx, [ebp - 4]
    add ebx, [esi + 12]
    mov al, [ebx + ecx]
    cmp al, '/'
    jne .copy_character

    ; Write NUL-terminator
    mov ebx, [ebp - 12]
    mov [ebx + ecx], byte 0x00
    jmp .finished

.copy_character:
    mov ebx, [ebp - 12]
    mov [ebx + ecx], al

    inc ecx

    ; Input Bounds Condition
    cmp ecx, [ebp - 8]
    jae .finished

    ; Output Bounds Condition
    cmp ecx, [ebp - 16]
    jb .copy_loop

    ; If no more data can be written to the buffer but the
    ; element didn't end yet, the element's full length has
    ; to be gotten for the return value.

.counter_loop:
    mov ebx, [ebp - 4]
    cmp [ebx + ecx], byte '/'
    je .finished

    inc ecx
    cmp ecx, [ebp - 8]
    jb .counter_loop

.finished:
    add esp, 16

    ; Store return value for *popad* to restore
    mov [esp + 28], ecx

    ; Restore registers & Return
    popad
    ret

