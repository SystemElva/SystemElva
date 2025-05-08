
; count_ones:
;   Count number of set bits  in a Uint32. This is particularly useful for
;   checking whether a number is a power of two. Powers of two have only a
;   single bit bit set to one in binary.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     0.  U32       value
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Number of bits in the given value.
count_ones:
.prolog:
    pushad

.setup_checker_loop:
    xor ecx, ecx
    xor edx, edx

.checker_loop:
    mov eax, [ebp - 4]
    shr eax, cl
    and eax, 1

    cmp eax, 0
    je .zero
    inc edx

.zero:
    inc ecx
    cmp ecx, 32
    jb .checker_loop

.epilog:
    mov [esp + 28], edx
    popad
    ret
