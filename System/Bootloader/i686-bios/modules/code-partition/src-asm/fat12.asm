
FAT12_LOGICAL_SECTORS_PER_CLUSTER   equ 0x0d
FAT12_NUM_RESERVED_SECTORS          equ 0x0e
FAT12_FAT_COUNT                     equ 0x10
FAT12_MAXIMUM_RDR_ENTRIES           equ 0x11
FAT12_LOGICAL_SECTORS_PER_FAT       equ 0x16

FAT12_DIRENT_CLUSTER_START          equ 0x1a



; fat12_find_in_root_directory_region:
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     2.  Ptr32     name
;     1.  Ptr32     file_buffer         (32 bytes)
;     0.  Ptr32     partition_reader    (32 bytes)
fat12_search_in_root_directory_region:
.prolog:
    pushad
    sub esp, 32
    mov esi, esp

    ; Stack contents over the course of this function:
    ;
    ;   | ESI + | Bytes | Description                     |
    ;   | ----- | ----- | ------------------------------- |
    ;   |  0    |  4    |  name_pointer (argument)        |
    ;   |  4    |  4    |  partition_reader (argument)    |
    ;   |  8    |  4    |  file_buffer (argument)         |
    ;   |  12   |  4    |  root_directory_region_start    |
    ;   |  30   |  2    |  root_directory_entry_count     |
    ;   |       |       |                                 |

    mov eax, [ebp - 12]
    mov [esi], eax

    mov eax, [ebp - 8]
    mov [esi + 8], eax

    mov eax, [ebp - 4]
    mov [esi + 4], eax

.gather_fs_information:
    push ebp
    mov ebp, esp
    push dword [esi + 4]
    push dword SECTOR_READER_BUFFER
    push dword 0
    call disk_read_sector
    mov esp, ebp
    pop ebp

    ; Count the number of sectors before the RDR
    xor eax, eax
    xor edx, edx
    mov ax, [SECTOR_READER_BUFFER + FAT12_FAT_COUNT]
    mov dl, [SECTOR_READER_BUFFER + FAT12_NUM_RESERVED_SECTORS]
    mul edx

    mov dx, [SECTOR_READER_BUFFER + FAT12_NUM_RESERVED_SECTORS]
    add eax, edx
    mov [esi + 12], eax

    mov dx, [SECTOR_READER_BUFFER + FAT12_MAXIMUM_RDR_ENTRIES]
    mov [esi + 30], dx

.setup_root_directory_loop:
    xor ecx, ecx ; Root directory entry index

.root_directory_loop:
    ; Test whether this entry is a multiple of 16, because if it is
    ; -> A new sector must be loaded
    mov eax, ecx
    and eax, 0x0f
    cmp eax, 0
    jne .check_entry

.load_new_sector:
    ; Calculate the index of the sector to load
    mov eax, ecx
    shr eax,  4
    add eax, [esi + 12]

    push ebp
    mov ebp, esp
    push dword [esi + 4]
    push dword SECTOR_READER_BUFFER
    push eax
    call disk_read_sector
    mov esp, ebp
    pop ebp

.check_entry:
    ; Get the byte offset of the current entry
    mov ebx, ecx
    shl ebx, 5
    add ebx, SECTOR_READER_BUFFER

    push ebp
    mov ebp, esp
    push ebx
    push dword [esi]
    push dword 11
    call memory_equal
    mov esp, ebp
    pop ebp

    cmp eax, 0
    je .root_directory_loop_bounds_condition

.entry_found:
    mov eax, [esi + 8]
    push ebp
    mov ebp, esp
    push eax        ; Destination:  File Buffer
    push ebx        ; Source:       Directory Entry
    push dword 32   ; Byte Count
    call memory_copy
    mov esp, ebp
    pop ebp

    ; Return success value (0)
    mov esp, esi
    add esp, 32
    popad
    xor eax, eax
    ret

.root_directory_loop_bounds_condition:
    inc cx
    cmp cx, [esi + 30]
    jb .root_directory_loop

    ; Return Error: Not Found
.epilog:
    add esp, 32
    popad
    mov eax, 1
    ret

.destination:
    dw 0xffff



; fat12_find:
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     2.  Ptr32     name
;     1.  Ptr32     file_buffer         (32 bytes)
;     0.  Ptr32     partition_reader    (32 bytes)
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
fat12_search:
.prolog:
    pushad
    sub esp, 32
    mov esi, esp

    mov eax, [ebp - 12]
    mov [esi], eax

    mov eax, [ebp - 4]
    mov [esi + 4], eax

.split_root_item_name:
    mov edi, esi
    add edi, 12

    push ebp
    mov ebp, esp
    push edi
    push dword 11
    push word ' '
    call memory_set
    mov esp, ebp
    pop ebp

    mov [edi + 12], byte 0

.setup_splitter_loop:
    mov ebx, [esi]

    ; @todo: Test whether there is an initial slash (for an absolute path)
    ;        and return an error if there is none.
    inc ebx             ; Don't copy the initial slash
    xor ecx, ecx        ; Input Index
    xor edx, edx        ; Output Index

.splitter_loop:
    mov al, [ebx + ecx]
    cmp al, byte '/'
    je .search_in_rdr
    cmp al, byte 0x00
    je .search_in_rdr

    cmp al, byte '.'
    jne .after_suffix_check
    mov edx, 8
    inc ecx
    jmp .splitter_loop

.after_suffix_check:

    ; Enforce uppercase names
    cmp al, 'a'
    jb .copy_character
    cmp al, 'z'
    ja .copy_character
    sub al, 32

.copy_character:
    mov [edi + edx], al
    inc edx

    ; Check whether the first part is too long
    ; for being a valid root directory entry.
    inc ecx
    cmp ecx, 11
    jae .splitting_failed
    jmp .splitter_loop

.splitting_failed:
    mov esp, esi
    add esp, 32
    popad
    mov eax, 0xffffffff
    ret

.search_in_rdr:
    mov eax, [ebp - 8]
    push ebp
    mov ebp, esp
    push dword [esi + 4]
    push eax            ; File Buffer
    push edi
    call fat12_search_in_root_directory_region
    mov esp, ebp
    pop ebp

.epilog:
    add esp, 32
    popad
    ret



; fat12_open_file:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  Ptr32     path
;     1.  Ptr32     partition_reader    (32 bytes)
;     0.  Ptr32     file_buffer         (32 bytes)
;   [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    0xffffffff  (if file not found)
;               len_file    (otherwise)
fat12_open_file:
.prolog:
    pushad
    sub esp, 64
    mov esi, esp

.search_file:

    mov eax, [ebp - 8]
    mov ebx, [ebp - 12]

    push ebp
    mov ebp, esp
    push eax
    push dword 0
    push ebx
    call fat12_search
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push dword [ebp - 8]
    push dword 16
    push dword 1
    push dword 1
    push word FOREGROUND_LIGHT_RED
    call write_bytes
    mov esp, ebp
    pop ebp

    cli
    hlt

    ; Save a pointer to the partition reader
    mov ebx, [ebp - 4]
    mov eax, [ebp - 8]
    mov [ebx + 28], eax

    push ebp
    mov ebp, esp
    push eax
    push dword SECTOR_READER_BUFFER
    push dword 0
    call disk_read_sector
    mov esp, ebp
    pop ebp

    mov eax, [SECTOR_READER_BUFFER + FAT12_FAT_COUNT]

.epilog:
    add esp, 64
    popad
    ret



; fat12_load_file:
;   
;
; Arguments (4):
;   [FURTHEST FROM EBP]
;     3.  U32       num_bytes
;     2.  Ptr32     buffer
;     1.  U32       read_start
;     0.  Ptr32     file
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
fat12_read_from_file:
.prolog:
    pushad
    sub esp, 32
    mov esi, esp

.find_file:
    ; 

.epilog:
    add esp, 32
    popad
    ret

