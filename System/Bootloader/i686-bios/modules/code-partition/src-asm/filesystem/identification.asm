
; Numeric identifiers for filesystems

FILESYSTEM_UNKNOWN equ 0

FILESYSTEM_FAT12 equ 1
FILESYSTEM_FAT16 equ 2
FILESYSTEM_FAT32 equ 3
FILESYSTEM_EXFAT equ 4



; identify_fat12:
;   Check whether a given partition contains a FAT12-filesystem.
; 
; Arguments:
;   [FURTEHST FROM STACK-TOP]
;     0.  Ptr32     partition_reader
;   [NEAREST TO STACK-TOP]
; 
; Return Value:
;   - [EAX]:    1 if the partiton contains a FAT12 filesystem,
;               0 otherwise
identify_fat12:
.prolog:
    pushad
    sub esp, 32
    mov esi, esp

.load_first_sector:
    mov eax, [ebp - 4]
    push ebp
    mov ebp, esp
    push eax
    push dword 0
    call disk_push_sector
    mov esp, ebp
    pop ebp
    mov edi, eax

.check_bytes_per_logical_sector:
    ; Check whether the number of bytes per logical sector is a power
    ; of two. It must be a power of two above 32.

    xor eax, eax
    mov ax, [edi + 0x0b]

    cmp ax, 32
    jb .false

    push ebp
    mov ebp, esp
    push eax
    call count_ones
    mov esp, ebp
    pop ebp

    cmp eax, 1
    jne .false

.setup_oem_name_loop:
    xor ecx, ecx

    ; Make pointer to first character of OEM Name
    mov ebx, edi
    add ebx, 3

.oem_name_loop:
    xor ax, ax
    mov al, [ebx + ecx]

    push ebp
    mov ebp, esp
    push ax
    call is_printable
    mov esp, ebp
    pop ebp
    cmp eax, 0
    je .false

    inc ecx
    cmp ecx, 8
    jb .oem_name_loop

.check_boot_signature:
    cmp [edi + 510], word 0xaa55
    jne .false

.true:
    add esp, 32
    mov [esp + 28], dword 1
    jmp .epilog

.false:
    add esp, 32
    mov [esp + 28], dword 0

.epilog:
    popad
    ret



; identify_filesystem:
;   Try to find out which filesystem a partition contains.
; 
; Arguments:
;   [FURTEHST FROM EBP]
;     0.  Ptr32     partition_reader
;   [NEAREST TO EBP]
; 
; Return Value:
;   - [EAX]:    Filesystem Identifier
identify_filesystem:
.prolog:
    pushad
    mov esi, esp
    mov edi, [ebp - 4]

.check_filesystems:
    push ebp
    mov ebp, esp
    push edi
    call identify_fat12
    mov esp, ebp
    pop ebp

    cmp eax, 0
    je .not_fat12

    popad
    mov eax, FILESYSTEM_FAT12
    ret

.not_fat12:

.epilog:
    popad
    mov eax, FILESYSTEM_UNKNOWN
    ret

