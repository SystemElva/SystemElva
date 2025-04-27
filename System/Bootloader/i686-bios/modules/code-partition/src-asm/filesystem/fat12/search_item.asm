
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
;             1.  Containing Folder Cluster
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
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  Ptr32                         item_name
;     1.  Ptr32                         filesystem
;     0.  Ptr32                         result
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
;
; Red Zone (32 bytes):
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
;   |       |       |                                 |
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

    push text.config_path
    jmp crash_with_text

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
;     2.  U32       first_cluster
;     1.  Ptr32     item_name
;     0.  Ptr32     filesystem
;   [NEAREST TO EBP]
;
; Return Value:
fat12_search_item_in_subfolder:
.prolog:
    pushad
    ; 32 bytes for register excess, 512 bytes because of the maximum
    ; number of bytes possible to be used in FAT12 folder item names.
    sub esp, (512 + 32)
    mov esi, esp

.search_file:
    ; 

.epilog:
    add esp, (512 + 32)
    popad
    ret

