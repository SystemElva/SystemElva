
FAT12_DIRENT_CLUSTER_START          equ 0x1a
FAT12_DIRENT_ATTRIBUTES             equ 0x0b

; fat12_search_item:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  Ptr32     data_buffer
;
;           16-byte buffer to which four 4-byte information pieces
;           about the found file will be written:
;
;             0.  File's First Cluster
;             1.  Containing Folder's First Cluster
;             2.  Directory Table Index
;             3.  File Length               (0xffffffff for folders)
;
;     1.  Ptr32     path
;
;           NUL-terminated Absolute path to file, using forward
;           slashes as splitter and UTF-8 as encoding.
;
;     0.  Ptr32     filesystem
;
;           FAT12-filesystem in which to search.
;
;   [NEAREST TO EBP]
;
;
; Red Zone (512 + 32 =  544 bytes):
;
;   | ESI + | Bytes | Description                     |
;   | ----- | ----- | ------------------------------- |
;   | 0x00  |  4    |  filesystem                  *  |
;   | 0x04  |  4    |  path                        *  |
;   | 0x10  |  4    |  current_item_first_cluster     |
;   | 0x14  |  4    |  last_item_first_cluster        |
;   | 0x18  |  4    |  last_directory_table_index     |
;
; > Items marked with an asterisk (*) are duplicates of an
; > argument, used for giving to another procedure within
; > a new stack frame.
;
; Return Value:
;   N/A
fat12_search_item:
.prolog:
    pushad
    sub esp, (512 + 32)
    mov esi, esp

    mov eax, [ebp - 4]
    mov [esi], eax

    mov eax, [ebp - 8]
    mov [esi + 4], eax

.search_item_in_root:
    push ebp
    mov ebp, esp
    push dword [esi + 4]            ; path
    call string_length
    mov esp, ebp
    pop ebp

.copy_root_element_name:
    mov ebx, esi
    add ebx, 32

    push ebp
    mov ebp, esp
    push dword [esi + 4]            ; path
    push eax                        ; len_path
    push ebx                        ; buffer
    push dword 512                  ; len_buffer
    push dword 0                    ; element_index
    call path_copy_element
    mov esp, ebp
    pop ebp

    cmp eax, 0xffffffff
    je .failed
    
    mov ecx, esi
    add ecx, 16

    mov eax, [ebp - 4]

    ; Search for the root folder item named in the buffer
    push ebp
    mov ebp, esp
    push ecx                        ; result value pointer
    push eax                        ; filesystem
    push ebx                        ; item_name
    call fat12_search_item_in_root_folder
    mov esp, ebp
    pop ebp

.setup_subpath_loop:
    mov eax, [ecx + 8]

.subpath_loop:

    push ebp
    mov ebp, esp
    push dword [esi + 4]            ; path
    push eax                        ; len_path
    push ebx                        ; buffer
    push dword 512                  ; len_buffer
    push dword 0                    ; element_index
    call path_copy_element
    mov esp, ebp
    pop ebp

    mov eax, esi
    add eax, 16

    push ebp
    mov ebp, esp
    push eax
    push dword [esi]
    push dword [esi + 10]
    push ebx
    call fat12_search_item_in_subfolder
    mov esp, ebp
    pop ebp

    cmp eax, 0xffffffff
    je .leaf_found

    cli
    hlt

.leaf_found:

cli
hlt

.failed:
.epilog:
    add esp, (512 + 32)
    popad
    ret



; fat12_postprocess_short_filename:
;   
;
; Arguments (4):
;   [FURTHEST FROM EBP]
;     1.  Ptr32                         buffer          (12 bytes)
;     0.  Ptr32                         item_name
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
;
fat12_postprocess_short_filename:
.prolog:
    pushad
    sub esp, 32
    mov esi, esp

    mov eax, [ebp - 4]
    mov [esi + 4], eax

    mov eax, [ebp - 8]
    mov [esi + 8], eax


.prepare:
    mov edx, dword [esi + 8]

    push ebp
    mov ebp, esp
    push edx
    push dword 11
    push word ' '
    call memory_set
    mov esp, ebp
    pop ebp

    mov [edx + 11], byte 0x00

.setup_name_copy_loop:
    mov ebx, [ebp - 4]
    mov edx, dword [esi + 8]
    xor ecx, ecx        ; Character index

.name_copy_loop:
    cmp [ebx + ecx], byte 0x00
    je .determine_suffix_existence

    cmp [ebx + ecx], byte '.'
    je .determine_suffix_existence

    mov al, [ebx + ecx]
    mov [edx + ecx], al

    inc ecx
    cmp ecx, 8
    jb .name_copy_loop

.determine_suffix_existence:
    cmp [ebx + ecx], byte '.'
    jne .epilog
    inc ecx ; Jump over dot

.setup_suffix_copy_loop:
    add ebx, ecx        ; Start of suffix in input
    mov edx, [ebp - 8]  ; Start of buffer
    add edx, 8          ; Add offset of suffix buffer-part
    xor ecx, ecx        ; Character index

.suffix_copy_loop:
    cmp [ebx + ecx], byte 0x00
    je .epilog

    mov al, [ebx + ecx]
    mov [edx + ecx], al

    inc ecx
    cmp ecx, 3
    jb .suffix_copy_loop

.epilog:
    add esp, 32
    popad
    ret



; fat12_search_item_in_root_folder:
;   @todo
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  Ptr32                         item_name
;     1.  Ptr32                         filesystem
;     0.  Ptr32                         result
;
;                   0.  u32             first_cluster
;                   1.  u32             byte_count      (0xffffffff for folders)
;                   2.  u32             table_index
;
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
;
; Red Zone (512 + 12 + 32 =  556 bytes):
;
;   | ESI + | Bytes | Description                     |
;   | ----- | ----- | ------------------------------- |
;   | 0x00  |  4    |  result                      *  |
;   | 0x04  |  4    |  filesystem                  *  |
;   | 0x08  |  4    |  item_name                   *  |
;   | 0x0c  |  4    |  sector_buffer                  |
;   | 0x10  |  4    |  root_folder_start              |
;   | 0x14  |  4    |  current_folder_entry           |
;   | 0x18  |  4    |  short_filename_buffer_pointer  |
;   | 0x1e  |  2    |  root_folder_capacity           |
;   | 0x20  |  512  |  long_filename_collector    [1] |
;   | 0x220 |  32   |  short_filename_buffer          |
;   |       |       |                                 |
;
; [1]: This is used for collecting LFN  entries one after the other until the
;      full entry has been gotten. That string is then compared to the argument.
;
; > Items marked with an asterisk (*) are duplicates of an
; > argument, used for giving to another procedure within
; > a new stack frame.
;
fat12_search_item_in_root_folder:
.prolog:
    pushad
    sub esp, (512 + 12 + 32)
    mov esi, esp

    ; Result Pointer
    mov eax, [ebp - 4]
    mov [esi], eax

    ; Filesystem Pointer
    mov eax, [ebp - 8]
    mov [esi + 0x04], eax

    ; Item name
    mov ebx, [ebp - 12]
    mov [esi + 0x08], ebx

    mov ebx, [eax + 0x24]
    mov [esi + 0x10], ebx

    mov     bx,                 [eax + 0x28]
    mov     [esi + 0x1e],       bx

    mov     eax,                esi
    add     eax,                (512 + 32)
    mov     [esi + 0x18],       eax

.prepare_short_filename:
    push ebp
    mov ebp, esp
    push dword [esi + 0x08]
    push eax
    call fat12_postprocess_short_filename
    mov esp, ebp
    pop ebp

.setup_main_search_loop:
    mov     ebx,                [ebp - 8]
    mov     ebx,                [ebx + 0x20]

    push    ebp
    mov     ebp,                esp
    push    ebx
    push    dword [esi + 0x10]
    call    disk_push_sector
    mov     esp,                ebp
    pop     ebp

    mov     [esi + 0x0c],       eax
    xor     ecx,                ecx                 ; Table Entry Index

.main_search_loop:
    cmp ecx, [esi + 0x10]
    jae .not_found

    ; Check whether a new sector must be loaded
    mov eax, ecx
    and eax, 0x0f
    cmp eax, 0
    ja .check_entry

    ; Load new sector

    ;; Get Partition Reader
    mov     ebx,                [esi + 0x04]        ; FAT12 filesystem
    mov     edx,                [ebx + 0x20]        ; Partition Reader

    ;; Add current sector
    mov     eax,                ecx
    shr     eax,                4
    add     eax,                [ebx + 0x24]        ; Add Root Directory Start

    mov     ebx,                [esi + 0x0c]        ; Sector Buffer

    push    ebp
    mov     ebp,                esp
    push    edx
    push    eax
    push    ebx
    call    disk_read_sector
    mov     esp,                ebp
    pop     ebp

.check_entry:
    mov     eax,                ecx
    and     eax,                0x0f
    shl     eax,                5
    add     eax,                [esi + 0x0c]        ; Sector Buffer

    mov     [esi + 0x14],       eax

    ; Check if this is a long filename entry (Attributes field containing 0x0f)
    cmp     [eax + FAT12_DIRENT_ATTRIBUTES], byte 0x0f
    jne     .check_short_filename

.collect_long_filename:
    ; @todo: Collect long filename entry and compare the
    ;        name to the one that is being searched.

    push text.long_filename_unimplemented
    jmp crash_with_text

.check_short_filename:

    mov eax, esi
    add eax, 32

    push ebp
    mov ebp, esp
    push dword [esi + 0x14]
    push dword [esi + 0x18]
    push dword 11
    call memory_equals_ignore_case
    mov esp, ebp
    pop ebp

    cmp eax, 0
    je .next_entry

.extract_values:
    mov edi, [esi] ; Result Structure
    mov [edi + 8], dword 0xffffffff ; File Size (directory dummy value)

    mov ebx, [esi + 0x14]
    mov al, [ebx + FAT12_DIRENT_ATTRIBUTES]
    and al, 0x10
    cmp al, 0
    jne .is_folder

    mov eax, [ebx + FAT12_DIRENT_FILE_SIZE]
    mov dword [edi + 8], eax

.is_folder:
    xor eax, eax
    mov ax, [ebx + FAT12_DIRENT_START_CLUSTER]
    mov [edi + 4], eax
    mov [edi + 12], ecx

    mov [edi], word 0 ; Success
    mov [edi + 2], word 3 ; Three result values

    push ebp
    mov ebp, esp
    push word 1
    call disk_pop_sectors
    mov esp, ebp
    pop ebp

    add esp, (512 + 12 + 32)
    popad
    ret

.next_entry:
    inc ecx
    jmp .main_search_loop

.not_found:
    push ebp
    mov ebp, esp
    push word 1
    call disk_pop_sectors
    mov esp, ebp
    pop ebp

    add esp, (512 + 12 + 32)
    popad
    ret



; fat12_search_item_in_subfolder:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     3.  Ptr32     item_name
;     2.  U32       first_cluster
;     1.  Ptr32     filesystem
;     0.  ptr32     result
;
;                   0.  u32             first_cluster
;                   1.  u32             byte_count      (0xffffffff for folders)
;                   2.  u32             table_index
;
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
;
; Red Zone (512 + 12 + 64 =  588 bytes):
;
;   | ESI + | Bytes | Description                     |
;   | ----- | ----- | ------------------------------- |
;   | 0x00  |  4    |  result                      *  |
;   | 0x04  |  4    |  filesystem                  *  |
;   | 0x08  |  4    |  first_cluster               *  |
;   | 0x0c  |  4    |  item_name                   *  |
;   | 0x10  |  4    |  fat_start                      |
;   | 0x14  |  4    |  data_area_start                |
;   | 0x18  |  4    |  fat_sector_buffer              |
;   | 0x1c  |  4    |  folder_table_sector_buffer     |
;   | 0x20  |  4    |  current_cluster_index          |
;   |       |       |                                 |
;
fat12_search_item_in_subfolder:
.prolog:
    pushad
    ; 32 bytes for register excess, 512 bytes because of the maximum
    ; number of bytes possible to be used in FAT12 folder item names.
    sub esp, (512 + 12 + 64)
    mov esi, esp

    ; Store arguments
    
    ;; Result
    mov eax, [ebp - 0x04]
    mov [esi], eax

    ;; Filesystem
    mov eax, [ebp - 0x08]
    mov [esi + 0x04], eax

    ;; First Cluster
    mov eax, [ebp - 0x0c]
    mov [esi + 0x08], eax

    ;; Item Name
    mov eax, [ebp - 0x10]
    mov [esi + 0x0c], eax

    ; Get FAT area start
    xor ecx, ecx
    mov ebx, [esi + 0x04]   ; Filesystem
    mov cx, [ebx + 0x2e]    ; Number of reserved sectors
    mov [esi + 0x10], cx

    ; Calculate data_area_start

    ;; Calculate size of FATs
    mov ebx, [esi + 0x04] ; Filesystem
    xor eax, eax
    xor edx, edx
    mov ax, [ebx + 0x2a] ; FAT Size (in sectors)
    mov dl, [ebx + 0x2c] ; FAT count
    mul edx

    ;; Get size of RDR in sectors
    xor edx, edx
    mov dx, [ebx + 0x28] ; Root Directory Region's capacity (in entries)
    shr edx, 4
    add eax, edx
    add eax, ecx

    ;; Store the data_area_start into the red zone
    mov [esi + 0x14], eax

    ; Get Partition Identifier
    mov ebx, [ebx + 0x20]

    ; Reserve place for folder table sector
    push ebp
    mov ebp, esp
    push ebx
    push dword 0 ; placeholder
    call disk_push_sector
    mov esp, ebp
    pop ebp
    mov [esi + 0x1c], eax

    ; Load (first sector of) FAT
    mov eax, [esi + 0x10]
    push ebp
    mov ebp, esp
    push ebx
    push eax ; placeholder
    call disk_push_sector
    mov esp, ebp
    pop ebp
    mov [esi + 0x1c], eax

.setup_search_loop:
    ;; Initialize current cluster index within the file allocation table)
    ;; to the directory's first cluster.
    mov eax, [esi + 0x08]
    mov [esi + 0x20], eax

    xor ecx, ecx    ; Table Entry index

.search_loop:
    mov eax, ecx
    and eax, 0x0a
    cmp eax, 0
    ja .setup_sector_loop

    ; Check whether a new cluster must be retrieved

    xor edx, edx
    mov ebx, [esi + 4]
    mov dl, [ebx + 0x2d]    ; Sectors per cluster
    mov eax, ecx    ; Table Entry Index
    div edx
    ;; Check whether there is a remainder (if there is one, no new cluster
    ;; must be retrieved, because the current cluster contains more sectors).
    cmp edx, 0
    ja .load_next_sector

.load_next_sector:
    ; EDX contains the sector index within this cluster
    add ebx, edx

    ; Calculate current cluster's start
    xor edx, edx
    mov dl, [esi + 0x2d]    ; Sectors per cluster
    mov eax, [esi + 0x20]   ; Current cluster index
    mul edx
    add eax, [esi + 0x14]   ; Data Area Start
    ;; Add current sector's offset
    add eax, ebx
    mov ebx, eax

    ; Multiply with 1.5
    mov eax, [esi + 0x20]       ; Current Cluster Index
    mov edx, 3
    mul edx
    mov edx, 2
    div edx

    cmp edx, 1
    je .odd_entry

    ; Even Entry
    mov ebx, [esi + 0x10]

.odd_entry:
    

.setup_sector_loop:


    and eax, 0x0a
    shl eax, 5


    inc ecx
    jmp .search_loop

.epilog:
    push ebp
    mov ebp, esp
    push word 1
    call disk_pop_sectors
    mov esp, ebp
    pop ebp

    add esp, (512 + 12 + 64)
    popad
    ret

