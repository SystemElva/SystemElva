
FAT12_LOGICAL_SECTORS_PER_CLUSTER   equ 0x0d
FAT12_NUM_RESERVED_SECTORS          equ 0x0e
FAT12_FAT_COUNT                     equ 0x10
FAT12_MAXIMUM_RDR_ENTRIES           equ 0x11
FAT12_LOGICAL_SECTORS_PER_FAT       equ 0x16

FAT12_DIRENT_CLUSTER_START          equ 0x1a
FAT12_DIRENT_ATTRIBUTES             equ 0x0b



; fat12_search_in_directory_table:
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     4.  Ptr32     name
;     3.  U32       table_entry_index
;     2.  U32       num_sectors
;     1.  U32       first_sector
;               First sector of the complete directory table
;
;     0.  Ptr32     partition_reader    (32 bytes)
;
; Return Value:
;   - [EAX]:    Equality:       1
;               Inequality      0
fat12_directory_entry_equals:
.prolog:
    pushad
    sub esp, 32
    mov esi, esp

    ; Stack contents over the course of this function:
    ;
    ;   | ESI + | Bytes | Description                     |
    ;   | ----- | ----- | ------------------------------- |
    ;   |  0    |  4    |  partition_reader (argument)    |
    ;   |  4    |  4    |  name_pointer (argument)        |
    ;   |  8    |  4    |  file_buffer (argument)         |
    ;   |       |       |                                 |

    ; If this cannot be a long filename - enabled entry because
    ; of being the first entry in the directory table.
    mov eax, [ebp - 16]
    cmp eax, 0
    je .check_short_entry

    xor ecx, ecx

.long_filename_entry_counter_loop:
    ; There can be at most 20 LFN entries in a row
    cmp ecx, 20
    ja .invalid_entries

    ; Load previous sector if this is the
    ; first entry in this sector
    mov eax, [ebp - 16]
    and eax, 0x0f
    cmp eax, 0
    ja .is_entry_long_filename

.load_previous_sector:
    ; Calculate sector within table
    mov eax, [ebp - 16]
    cmp eax, ecx            ; Check whether this would go before the
    jae .invalid_entries    ; first entry of the directory table
    sub eax, ecx
    shr eax, 4

    ; Add table start
    add eax, [ebp - 8]

    ; Load sector
    push ebp
    mov ebp, esp
    push dword [esi]
    push dword (SECTOR_READER_BUFFER + 512) ; A secondadry sector reader buffer is used
    push eax                                ; because this function is used in other
    call disk_read_sector                   ; functions which may already use another sector
    mov esp, ebp
    pop ebp

.is_entry_long_filename:
    ; Get entry offset within sector
    mov ebx, [ebp - 16]
    sub ebx, ecx
    and ebx, 0x0f

    ; Calculate address of current entry as loaded in memory
    shl ebx, 5
    add ebx, (SECTOR_READER_BUFFER + 512)

    cmp [ebx + FAT12_DIRENT_ATTRIBUTES], byte 0x0f ; Attributes for LFN entries
    je .long_filename_end_found

    inc ecx
    jmp .long_filename_entry_counter_loop

.long_filename_end_found:
    cli
    hlt

.check_short_entry:


.invalid_entries:
.inequality:


.equality:
    add esp, 32
    popad
    mov eax, 1
    ret




; fat12_search_in_directory_table:
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     4.  Ptr32     name
;     3.  Ptr32     file_buffer         (32 bytes)
;     2.  U32       num_sectors
;     1.  U32       first_sector
;     0.  Ptr32     partition_reader    (32 bytes)
;
; Return Value:
;   - [EAX]:    Success:  Index of file index
;               Failure:  0xffffffff 
fat12_search_in_directory_table:
.prolog:
    pushad
    sub esp, 32
    mov esi, esp

    ; Stack contents over the course of this function:
    ;
    ;   | ESI + | Bytes | Description                     |
    ;   | ----- | ----- | ------------------------------- |
    ;   |  0    |  4    |  partition_reader (argument)    |
    ;   |  4    |  4    |  name_pointer (argument)        |
    ;   |  8    |  4    |  file_buffer (argument)         |
    ;   |       |       |                                 |

.setup_table_loop:
    xor ecx, ecx

.table_loop:
    ; Exit condition (end of table reached)
    mov eax, ecx
    shr eax, 4
    cmp eax, [ebp - 12]

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
    add eax, [ebp - 8]

    push ebp
    mov ebp, esp
    push dword [esi]
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
    jne .entry_found

    inc ecx
    jmp .table_loop

.entry_found:
    cli
    hlt

.epilog:
    add esp, 32
    popad
    ret



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

    ; Get sector count of table
    mov edx, [esi + 30]
    shr edx, 5

    push ebp
    mov ebp, esp
    push dword [esi + 4]
    push dword [esi + 12]
    push edx                ; Sector Count
    push ecx                ; Table Entry Index
    push dword [esi]
    call fat12_directory_entry_equals
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
;   - [EAX]:    0xffffffff  (on error)
;               0           (on success)
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

    cmp eax, 0
    je .root_directory_entry_found

    mov esp, esi
    add esp, 32
    popad
    mov eax, 0xffffffff
    ret

.root_directory_entry_found:
    


.epilog:
    add esp, 32
    popad
    mov eax, 0
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

