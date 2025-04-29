
; memory_equal:
;   Check whether two memory regions contain equal values.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     2.  U32       len_regions
;     1.  Ptr32     region_2
;     0.  Ptr32     region_1
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]: 1 if equal, 0 if not equal.
;
memory_equal:
    pushad

.setup_checker_loop:
    xor     ecx,                ecx
    mov     esi,                [ebp - 4]
    mov     edi,                [ebp - 8]

    mov     eax,                1       ; Return Value

.checker_loop:
    cmp     ecx,                [ebp - 12]
    jae     .finish

    mov     dh,                 [esi + ecx]
    mov     dl,                 [edi + ecx]
    cmp     dh,                 dl
    jne     .not_equal

    inc     ecx
    jmp     .checker_loop

.not_equal:
    xor     eax,                eax

.finish:
    mov     [esp + 28],         eax
    popad
    ret



; memory_copy:
;   Copy the content of one memory region to another location. This function
;   starts at the first byte and advances forwards.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     2.  U32       len_regions     (only lower byte used)
;     1.  Ptr32     source
;     0.  Ptr32     destination
;  [NEAREST TO EBP]
;
memory_copy:
.prolog:
    pushad

.setup_copy_loop:
    mov     esi,                [ebp - 8]
    mov     edi,                [ebp - 4]
    mov     edx,                [ebp - 12]
    xor     ecx,                ecx

.copy_loop:
    cmp     ecx,                edx
    jae     .epilog

    mov     al,                 [esi + ecx]
    mov     [edi + ecx],        al

    inc     ecx
    jmp     .copy_loop

.epilog:
    popad
    ret



; memory_set:
;   Repeats one value over all bytes of a given memory region.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     2.  U16       value           (only lower byte used)
;     1.  U32       len_region
;     0.  Ptr32     region
;  [NEAREST TO EBP]
;
memory_set:
.prolog:
    pushad

.setup_filler_loop:
    xor     ecx,                ecx
    mov     ebx,                [ebp - 4]
    mov     al,                 [ebp - 10]

.filler_loop:
    cmp     ecx,                [ebp - 8]
    jae     .epilog

    mov     [ebx + ecx],        al

    inc     ecx
    jmp     .filler_loop

.epilog:
    popad
    ret



; search_forwards:
;   Search the first occurrence of a value in a memory region,
;   searching from the first byte to the last one.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     2.  U16       value           (only lower byte used)
;     1.  U32       len_region
;     0.  Ptr32     region
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:            First occurrence of 'value' or 0xffffffff,
;                       if 'len_region' was reached first.
;
search_forwards:
.prolog:
    pushad

.setup_forwards_loop:
    xor     ecx,                ecx
    mov     ebx,                [ebp - 4]
    mov     ah,                 [ebp - 10]

.forwards_loop:
    mov     al,                 [ebx + ecx]
    cmp     al,                 ah
    je      .found

    inc     ecx
    cmp     ecx,                [ebp - 8]
    jb      .forwards_loop

    popad
    mov     eax,                0xffffffff
    ret

.found:
    mov     [esp + 28],         ecx
    popad
    ret

