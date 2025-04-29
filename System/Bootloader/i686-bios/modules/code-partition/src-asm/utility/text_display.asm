
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

