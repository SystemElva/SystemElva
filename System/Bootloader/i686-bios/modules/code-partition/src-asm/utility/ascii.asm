
; is_lowercase:
;   Check whether an UTF16LE-character is a lowercase letter
;
; Arguments:
;   [FURTHEST FROM EBP]
;     0.  U16       utf16le
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Given value if it is a lowercase letter
;               0 otherwise
is_lowercase:
.prolog:
    pushad
    xor eax, eax
    mov [esp + 28], eax

    cmp [ebp - 2], word 'a'
    jb .false
    
    cmp [ebp - 2], word 'z'
    ja .false
    
.true:
    mov ax, [ebp - 2]
    mov [esp + 28], eax

.false:
    popad
    ret



; is_uppercase:
;   Check whether an UTF16LE-character is an uppercase letter
;
; Arguments:
;   [FURTHEST FROM EBP]
;     0.  U16       utf16le
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Given value if it is an uppercase letter
;               0 otherwise
is_uppercase:
.prolog:
    pushad
    xor eax, eax
    mov [esp + 28], eax

    cmp [ebp - 2], word 'A'
    jb .false
    
    cmp [ebp - 2], word 'Z'
    ja .false
    
.true:
    mov ax, [ebp - 2]
    mov [esp + 28], eax

.false:
    popad
    ret



; is_letter:
;   Check whether an UTF16LE-character is a letter
;
; Arguments:
;   [FURTHEST FROM EBP]
;     0.  U16       utf16le
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Given value if it is a letter
;               0 otherwise
is_letter:
.prolog:
    pushad
    mov dx, [ebp - 2]

.check_lowercase:
    push ebp
    mov ebp, esp
    push dx
    call is_lowercase
    mov esp, ebp
    pop ebp

    cmp eax, 0
    je .check_uppercase

.lowercase:
    mov [esp + 28], eax
    popad
    ret

.check_uppercase:
    push ebp
    mov ebp, esp
    push dx
    call is_lowercase
    mov esp, ebp
    pop ebp

    cmp eax, 0
    ja .uppercase

.false:
    popad
    xor eax, eax
    ret

.uppercase:
    mov [esp + 28], eax
    popad
    ret



; is_printable:
;   Check whether an UTF16LE-character is a printable ASCII character
;
; Arguments:
;   [FURTHEST FROM EBP]
;     0.  U16       utf16le
;  [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    The printable character if it is one.
;               0 otherwise
is_printable:
.prolog:
    pushad
    mov dx, [ebp - 2]

    cmp eax, 32
    jb .false

    cmp eax, 127
    jae .false

.true:
    mov [esp + 28], eax
    popad
    ret

.false:
    popad
    xor eax, eax
    ret

