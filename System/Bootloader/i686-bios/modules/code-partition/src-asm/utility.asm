
FOREGROUND_BLACK         equ 0x00
FOREGROUND_BLUE          equ 0x01
FOREGROUND_GREEN         equ 0x02
FOREGROUND_CYAN          equ 0x03
FOREGROUND_RED           equ 0x04
FOREGROUND_MAGENTA       equ 0x05
FOREGROUND_BROWN         equ 0x06
FOREGROUND_LIGHT_GRAY    equ 0x07
FOREGROUND_DARK_GRAY     equ 0x08
FOREGROUND_LIGHT_BLUE    equ 0x09
FOREGROUND_LIGHT_GREEN   equ 0x0a
FOREGROUND_LIGHY_CYAN    equ 0x0b
FOREGROUND_LIGHT_RED     equ 0x0c
FOREGROUND_LIGHT_MAGENTA equ 0x0d
FOREGROUND_YELLOW        equ 0x0e
FOREGROUND_WHITE         equ 0x0f

BACKGROUND_BLACK         equ 0x00
BACKGROUND_BLUE          equ 0x10
BACKGROUND_GREEN         equ 0x20
BACKGROUND_CYAN          equ 0x30
BACKGROUND_RED           equ 0x40
BACKGROUND_MAGENTA       equ 0x50
BACKGROUND_BROWN         equ 0x60
BACKGROUND_LIGHT_GRAY    equ 0x70
BACKGROUND_DARK_GRAY     equ 0x80
BACKGROUND_LIGHT_BLUE    equ 0x90
BACKGROUND_LIGHT_GREEN   equ 0xa0
BACKGROUND_LIGHY_CYAN    equ 0xb0
BACKGROUND_LIGHT_RED     equ 0xc0
BACKGROUND_LIGHT_MAGENTA equ 0xd0
BACKGROUND_YELLOW        equ 0xe0
BACKGROUND_WHITE         equ 0xf0

; set_background:
;   Set a color from the BACKGROUND_* - value set as the
;   background color of the text output system's display.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     0.  U16       color_code (Only lower 8 bits used)
;  [NEAREST TO EBP]
;
; Return Value:
;   N/A
set_background:
.prolog:
    pushad

.action:
    mov ah, 0x0b
    mov bh, 0x00
    mov bl, [ebp - 2]
    shr bl, 4 ; Convert the BACKGROUND constant-value to a FOREGROUND one
    int 0x10

.epilog:
    popad
    ret



; write_text:
;   Put a NUL-terminated character string onto the display
;   using the BIOS functions at INT 0x10.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     3.  U16       color_code (Only lower 8 bits used)
;     2.  U32       start_cell
;     1.  U32       start_line
;     0.  Ptr32     string
;  [NEAREST TO EBP]
;
; Return Value:
;   N/A
write_text:
.prolog:
    pushad

.setup_character_loop:
    xor edi, edi

.character_loop:
    ; Check for primary exit condition (NUL character)
    mov ebx, [ebp - 4]
    add ebx, edi
    mov cl, [ebx]
    cmp cl, 0
    je .epilog

    ; Move Cursor
    mov ah, 0x02            ; Interrupt Function (move cursor)
    mov bh, 0               ; Display Page
    mov dx, [ebp - 8]       ; Start Column
    add dx, di
    mov dh, [ebp - 12]      ; Line
    int 0x10

    ; Check for secondary exit condition (line end reached)
    cmp dl, 80
    jae .epilog

    ; Display the character
    mov ah, 0x09
    mov al, cl
    mov bh, 0
    mov bl, [ebp - 14]
    mov cx, 1
    int 0x10

    inc edi
    jmp .character_loop

.epilog:
    popad
    ret



; write_bytes: @todo
;
; Arguments:
;   [FURTHEST FROM EBP]
;     4.  U16       color_code (Only lower 8 bits used)
;     3.  U32       start_cell
;     2.  U32       start_line
;     1.  U32       num_bytes
;     0.  Ptr32     bytes
;  [NEAREST TO EBP]
;
; Return Value:
;   N/A
write_bytes:
.prolog:
    pushad

.setup_character_loop:
    xor edi, edi            ; Character Index
    mov esi, [ebp - 4]

.character_loop:
    ; Check for primary exit condition (NUL character)
    cmp edi, [ebp - 8]
    je .epilog

    ; Move Cursor
    mov eax, edi
    mov edx, 3
    mul edx
    add eax, [ebp - 16]     ; Start Column
    mov dl, al
    mov dh, [ebp - 12]      ; Line
    mov ah, 0x02            ; Interrupt Function (move cursor)
    mov bh, 0               ; Display Page
    int 0x10

    xor ecx, ecx
    mov cl, [esi + edi]     ; Get Character
    shr cl, 4               ; Get Upper Nibble
    mov ebx, .lookup
    add ebx, ecx
    mov cl, [ebx]

    ; Display the character
    mov ah, 0x09
    mov al, cl
    mov bh, 0
    mov bl, [ebp - 18]
    mov cx, 1
    int 0x10

    ; Move Cursor
    mov eax, edi
    mov edx, 3
    mul edx
    add eax, [ebp - 16]     ; Start Column
    inc al
    mov dl, al
    mov dh, [ebp - 12]      ; Line
    mov ah, 0x02            ; Interrupt Function (move cursor)
    mov bh, 0               ; Display Page
    int 0x10

    xor ecx, ecx
    mov cl, [esi + edi]     ; Get Character
    and cl, 0x0f               ; Get Upper Nibble
    mov ebx, .lookup
    add ebx, ecx
    mov cl, [ebx]

    ; Display the character
    mov ah, 0x09
    mov al, cl
    mov bh, 0
    mov bl, [ebp - 18]
    mov cx, 1
    int 0x10

    inc edi
    jmp .character_loop

.epilog:
    popad
    ret

.lookup:
    db "0123456789abcdef"


; string_length:
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
string_length:
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



; memory_equal:
;   Check two memory regions for equality.
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
memory_equal:
    pushad

.setup_checker_loop:
    xor ecx, ecx
    mov esi, [ebp - 4]
    mov edi, [ebp - 8]

    mov eax, 1 ; Return Value

.checker_loop:
    cmp ecx, [ebp - 12]
    jae .finish

    mov dh, [esi + ecx]
    mov dl, [edi + ecx]
    cmp dh, dl
    jne .not_equal

    inc ecx
    jmp .checker_loop

.not_equal:
    xor eax, eax

.finish:
    mov [esp + 28], eax
    popad
    ret



; memory_copy:
;   Copy the content of one memory region to another.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     2.  U32       len_regions     (only lower byte used)
;     1.  Ptr32     source
;     0.  Ptr32     destination
;  [NEAREST TO EBP]
;
; Return Value:
;   N/A
memory_copy:
.prolog:
    pushad

.setup_copy_loop:
    mov esi, [ebp - 8]
    mov edi, [ebp - 4]
    mov edx, [ebp - 12]
    xor ecx, ecx

.copy_loop:
    cmp ecx, edx
    jae .epilog

    mov al, [esi + ecx]
    mov [edi + ecx], al

    inc ecx
    jmp .copy_loop

.epilog:
    popad
    ret



; memory_set:
;   Set a whole memory region's bytes to one value.
;
; Arguments:
;   [FURTHEST FROM EBP]
;     2.  U16       value           (only lower byte used)
;     1.  U32       len_region
;     0.  Ptr32     region
;  [NEAREST TO EBP]
;
; Return Value:
;   N/A
memory_set:
.prolog:
    pushad

.setup_filler_loop:
    xor ecx, ecx
    mov ebx, [ebp - 4]
    mov al, [ebp - 10]

.filler_loop:
    cmp ecx, [ebp - 8]
    jae .epilog
    mov [ebx + ecx], al
    inc ecx
    jmp .filler_loop

.epilog:
    popad
    ret



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
    mov ebx, [ebp - 4]

.checker_loop:
    mov eax, ebx
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

