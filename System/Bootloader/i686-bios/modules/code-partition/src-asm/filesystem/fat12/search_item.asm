
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
; Red Zone (512 + 64 =  576 bytes):
;
;   | ESI + | Bytes | Description                     |
;   | ----- | ----- | ------------------------------- |
;   | 0x00  |  4    |  filesystem                  *  |
;   | 0x04  |  4    |  path                        *  |
;   | 0x10  |  4    |  current_item_first_cluster     |
;   | 0x14  |  4    |  last_item_first_cluster        |
;   | 0x18  |  4    |  last_directory_table_index     |
;   | 0x30  |  16   |  incoming_results               |
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
    sub esp, (512 + 64)
    mov esi, esp

    mov eax, [ebp - 4]
    mov [esi], eax

    mov eax, [ebp - 8]
    mov [esi + 4], eax

.search_item_in_root:
    push ebp
    mov ebp, esp
    push dword [esi + 4]            ; path
    call strlen
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

    mov eax, [ecx + 0x04]
    mov [esi + 0x10], eax

.setup_subpath_loop:
    mov eax, [ecx + 8]
    mov ecx, 1

.subpath_loop:
    push ebp
    mov ebp, esp
    push dword [esi + 4]            ; path
    push eax                        ; len_path
    push ebx                        ; buffer
    push dword 512                  ; len_buffer
    push ecx                        ; element_index
    call path_copy_element
    mov esp, ebp
    pop ebp

    mov eax, esi
    add eax, 16

    push ebp
    mov ebp, esp
    push eax                        ; Result Buffer
    push dword [esi]                ; Filesystem
    push dword [esi + 0x10]         ; Current Item's First Clsuter
    push ebx                        ; Path Current Element
    call fat12_search_item_in_subfolder
    mov esp, ebp
    pop ebp

    push ebp
    mov ebp, esp
    push eax
    push dword 16
    push dword 1
    push dword 1
    push word FOREGROUND_WHITE
    call write_bytes
    mov esp, ebp
    pop ebp

    cli
    hlt

    cmp eax, 0xffffffff
    je .leaf_found

    cli
    hlt

.leaf_found:

cli
hlt

.failed:
.epilog:
    add esp, (512 + 64)
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



; fat12_is_long_file_name:
;   @todo
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;
;     0.  ptr32                         item_name
;
;   [NEAREST TO EBP]
;
; Return Value:
;   EAX:  u32                           0 for short file names
;                                       1 for long file names
;
fat12_is_long_file_name:
.prolog:
    pushad
    sub esp, 32

.get_string_length:
    mov     ebx,                [ebp - 4]   ; Argument: item_name

    push    ebp
    mov     ebp,                esp
    push    ebx                             ; String
    push    dword               16          ; Maximum length to check
    call    strlen
    mov     esp,                ebp
    pop     ebp
    mov     ecx,                eax

    cmp     eax,                11
    ja      .long_file_name

.check_name_length:
    mov     ebx,                [ebp - 4]   ; Argument: item_name

    push    ebp
    mov     ebp,                esp
    push    ebx
    push    ecx                             ; Sring Length
    push    word '.'
    call    search_forwards
    mov     esp,                ebp
    pop     ebp

    cmp     eax,                0xffffffff
    jne     .has_suffix

    ; If there is no separator but only the name, test whether the
    ; name itself (which is the complete string) only has 8 characters.
    cmp     ecx,                8
    ja      .long_file_name
    jmp     .short_file_name

.has_suffix:
    cmp     eax,                8
    ja      .long_file_name

.check_suffix_length:
    ; Advance onto the first point of 'item_name'.
    add     ebx,                eax
    ; Jump over  the point
    inc     ebx

    push    ebp
    mov     ebp,                esp
    push    ebx                             ; String
    push    dword               8           ; Maximum length to check
    call    strlen
    mov     esp,                ebp
    pop     ebp

    cmp     eax,                3
    ja      .long_file_name

.short_file_name:
    add     esp,                32
    popad
    xor     eax,                eax
    ret

.long_file_name:
    add     esp,                32
    popad
    mov     eax,                1
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
;   | 0x220 |  12   |  short_filename_buffer          |
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

    mov     ebp,                esp
    push    dword fat12_text.long_file_names_unimplemented
    jmp     crash

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
    mov ax, [ebx + FAT12_DIRENT_FIRST_CLUSTER]
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
;   | 0x1c  |  4    |  data_buffer                    |
;   | 0x20  |  4    |  current_cluster_index          |
;   | 0x24  |  4    |  next_cluster_index             |
;   | 0x240 |  12   |  short_filename                 |
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

    ;; Process a short filename
    mov eax, esi
    add eax, (512  + 64)

    push ebp
    mov ebp, esp
    push dword [esi + 0x0c]
    push eax
    call fat12_postprocess_short_filename
    mov esp, ebp
    pop ebp

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
    push eax
    call disk_push_sector
    mov esp, ebp
    pop ebp
    mov [esi + 0x18], eax

.setup_search_loop:
    ; Initialize current cluster index within the file allocation table)
    ; to the directory's first cluster.
    mov     eax,                [esi + 0x08]    ; Argument: first_cluster
    mov     [esi + 0x20],       eax
    mov     [esi + 0x24],       eax

    xor     ecx,                ecx             ; Initialize Table Entry Index

.search_loop:
    ; Check whether the current entry index is a multiple of 16, in which
    ; case, a new sector must be loaded.
    mov     eax,                ecx
    and     eax,                0x0f
    cmp     eax,                0
    ja      .folder_item_loop

.load_new_sector:
    ; @todo! Important: This doesn't work correctly. It doesn't load the
    ;        clusters based on whether a new cluster is needed.

    ; Check whether this sector's index is a multiple of the
    ; Sectors Per Cluster, in which case, a new cluster must be gotten.
    mov     ebx,                [esi + 0x04]    ; Filesystem
    mov     eax,                [esi + 0x20]
    mov     dl,                 [ebx + 0x2d]    ; Filesystem's Sectors Per Cluster
    xor     ebx,                ebx
    mov     bl,                 dl
    ;; If this is the table's first entry,
    ;; a new cluster must be retrieved anyways.
    cmp     ecx,                0
    je      .retrieve_next_cluster

    xor     edx,                edx
    div     ebx
    cmp     edx,                0
    ;; This jump is taken if a new cluster IS NOT needed.
    ja      .load_next_data_sector

.retrieve_next_cluster:
    mov     eax,                [esi + 0x24]    ; Next Cluster's Index
    mov     [esi + 0x20],       eax             ; Update Current Cluster's Index
    and     eax,                0xfff

    ; Check whether the directory's last cluster has already been loaded
    cmp     eax,                0xff0
    ja      .last_cluster_found

    ; Get the index of the next cluster

    ;; Integer-Multiply by 1.5 to get the byte index of the current entry.
    mov     eax,                [esi + 0x20]
    mov     edx,                3
    mul     edx
    ;; Check whether the intermediate value is zero, in which case,
    ;; a few steps can be (and MUST be) skipped.
    cmp     eax,                0
    je      .find_next_cluster_index

    mov     ebx,                2
    xor     edx,                edx
    div     ebx
    mov     edi,                eax             ; Save the current entry's index

.find_next_cluster_index:
    add     edx,                [esi + 0x10]    ; FAT Start Sector
    mov     ebx,                [esi + 0x18]    ; FAT Sector Buffer
    mov     ax,                 [ebx + eax]
    and     eax,                0xffff

    ; Decode the next cluster index

    mov     edx,                [esi + 0x20]
    and     edx,                1
    cmp     edx,                0
    je      .decode_even_cluster_index

.decode_odd_cluster_index:
    shr     ah,                 4
    and     eax,                0xffff
    jmp     .load_fat_sector

.decode_even_cluster_index:
    shl     al,                 4
    shr     ax,                 4
    and     eax,                0xffff

.load_fat_sector:
    mov     [esi + 0x24],       eax             ; Next Cluster's Index

    mov     ebx,                [esi + 0x18]    ; FAT Sector Buffer
    mov     edx,                [esi + 0x04]    ; Filesystem
    mov     edx,                [edx + 0x20]    ; Filesystem's Partition Reader

    push    ebp
    mov     ebp,                esp
    push    edx
    push    ebx
    push    eax                 ; Index of current FAT sector
    call    disk_read_sector
    mov     esp,                ebp
    pop     ebp

.load_next_data_sector:
    ; Calculate sector within cluster
    mov     edi,                ecx
    and     edi,                0x0f

    ; Calculate the sector index within the data region

    xor     eax,                eax
    add     eax,                edi
    add     eax,                [esi + 0x1c]

    mov ebx, [esi + 0x04]   ; Filesystem
    mov edx, [ebx + 0x20]   ; Filesystem's Partition Reader
    mov ebx, [esi + 0x14]

    push ebp
    mov ebp, esp
    push edx
    push eax
    push ebx
    call disk_read_sector
    mov esp, ebp
    pop ebp

.folder_item_loop:
    ; Calculate offset from start of sector to current entry.
    mov ebx, ecx
    and ebx, 0x0f
    shl ebx, 5

    add ebx, [esi + 0x1c] ; Buffer for Folder Table

    cmp [ebx + FAT12_DIRENT_ATTRIBUTES], byte 0x0f
    jne .short_filename_entry

    ; @todo: Collect long filename entry instead of crashing

    mov     ebp,                esp
    push    dword fat12_text.long_file_names_unimplemented
    jmp     crash

.short_filename_entry:
    mov eax, esi
    add eax, (512 + 64)

    push ebp
    mov ebp, esp
    push ebx
    push eax ; Short Filename in Red Zone
    push dword 11
    call memory_equals_ignore_case
    mov esp, ebp
    pop ebp

    cmp eax, 0
    je .next_entry

    ; Fill result structure

    xor eax, eax
    mov edi, 0xffffffff

    mov al, [ebx + FAT12_DIRENT_ATTRIBUTES]
    ; If this is a folder, EDI should stay 0xffffffff.
    and al, 0x10
    cmp al, 0
    ja .is_directory
    ; Otherwise, write the file's size into EDI for the return value.
    mov edi, [ebx+ FAT12_DIRENT_FILE_SIZE]

.is_directory:
    mov ax, [ebx+ FAT12_DIRENT_CLUSTER_START]

    mov ebx, [esi]
    mov [ebx + 0], word 0
    mov [ebx + 2], word 3
    mov [ebx + 4], eax
    mov [ebx + 8], edi
    mov [ebx + 12], ecx

    jmp .epilog

.next_entry:
    inc ecx
    jmp .search_loop

.last_cluster_found:
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

