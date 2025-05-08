
struc       GenericFilesystem

    .fn_open                    resd 1
    .fn_close                   resd 1
    .fn_read                    resd 1
    .fn_write                   resd 1
    .fn_stat                    resd 1
    .fn_destruct                resd 1

    .reserved                   resb 8
    .specifics                  resb 96

endstruc


struc       GenericFile

    .filesystem                 resd 1
    .flags                      resd 1
    .padding                    resb 8
    .specifics                  resb 16

endstruc

; open_filesystem:
;   
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     1.  ptr32<GenericFilesytem>               filesystem_buffer
;     0.  ptr32<Partition>                      partition
;   [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Identifier of loaded filesystem type, 0 on error.
open_filesystem:
.prolog:
    pushad

.identify_filesystem:
    mov     edx,                [ebp - 4]
    mov     ecx,                [ebp - 8]

    push    ebp
    mov     ebp,                esp
    push    edx                                 ; Partition
    call    identify_filesystem
    mov     esp,                ebp
    pop     ebp

    cmp     eax,                FILESYSTEM_FAT12
    je      .load_fat12

    cmp     eax,                FILESYSTEM_FAT16
    je      .load_fat16

    cmp     eax,                FILESYSTEM_FAT32
    je      .load_fat32

    cmp     eax,                FILESYSTEM_EXFAT
    je      .load_exfat

    jmp     .epilog

.load_fat12:
    push    ebp
    mov     ebp,                esp
    push    edx
    push    ecx
    call    fat12_open_filesystem
    mov     esp,                ebp
    pop     ebp

    jmp     .epilog

.load_fat16:
.load_fat32:
.load_exfat:

.epilog:
    mov     [esp + 28],         eax
    popad
    ret



; destruct_filesystem:
;   
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     0.  ptr32<GenericFilesytem>               filesystem
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
destruct_filesystem:
.prolog:
    pushad

.check_function_pointer:
    mov     ebx,                [ebp - 4]
    mov     eax,                [ebx + GenericFilesystem.fn_destruct]

    cmp     eax,                0
    je      .epilog

.redirect:
    push    ebp
    mov     ebp,                esp
    push    eax
    call    eax
    mov     esp,                ebp
    pop     ebp

.epilog:
    popad
    ret



; open_file:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  ptr32<char>                           utf8_path
;     1.  ptr32<GenericFile>                    file_buffer
;     0.  ptr32<GenericFilesytem>               filesystem
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
open_file:
.prolog:
    pushad

.redirect:
    mov     ebx,                [ebp - 4]
    mov     eax,                [ebx + GenericFilesystem.fn_open]

    mov     ebx,                [ebp - 4]
    mov     ecx,                [ebp - 8]
    mov     edx,                [ebp - 12]

    push    ebp
    mov     ebp,                esp
    push    ebx                                 ; filesystem
    push    ecx                                 ; file_buffer
    push    edx                                 ; utf8_path
    call    eax
    mov     esp,                ebp
    pop     ebx

.epilog:
    popad
    ret



; close_file:
;   
;
; Arguments (1):
;   [FURTHEST FROM EBP]
;     0.  ptr32<GenericFile>                    file
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
close_file:
.prolog:
    pushad

.redirect:
    ; Get fn_close from filesystem pointed to by file
    mov     ebx,                [ebp - 4]
    mov     ebx,                [ebx + GenericFile.filesystem]
    mov     eax,                [ebx + GenericFilesystem.fn_stat]

    mov     ebx,                [ebp - 4]

    push    ebp
    mov     ebp,                esp
    push    ebx                                 ; file
    call    eax
    mov     esp,                ebp
    pop     ebx

.epilog:
    popad
    ret



; get_file_statistics:
;   
;
; Arguments (4):
;   [FURTHEST FROM EBP]
;     3.  u32                                   len_path_buffer
;     2.  ptr32<char>                           utf8_path_buffer
;     1.  ptr32<GenericFileStat>                statistics_buffer
;     0.  ptr32<GenericFile>                    file
;   [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Length of the path
get_file_statistics:
.prolog:
    pushad

.redirect:
    ; Get fn_stat from filesystem pointed to by file
    mov     ebx,                [ebp - 4]
    mov     ebx,                [ebx + GenericFile.filesystem]
    mov     eax,                [ebx + GenericFilesystem.fn_stat]

    mov     ebx,                [ebp - 4]
    mov     ecx,                [ebp - 8]
    mov     edx,                [ebp - 12]
    mov     edi,                [ebp - 16]

    push    ebp
    mov     ebp,                esp
    push    ebx                                 ; file
    push    ecx                                 ; statistics_buffer
    push    edx                                 ; utf8_path_buffer
    push    edi                                 ; len_path_buffer
    call    eax
    mov     esp,                ebp
    pop     ebp

.epilog:
    popad
    ret



; read_file:
;   
;
; Arguments (4):
;   [FURTHEST FROM EBP]
;     3.  u32                                   num_bytes
;     2.  ptr32<u8>                             buffer
;     1.  u32                                   offset
;     0.  ptr32<GenericFile>                    file
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
read_file:
.prolog:
    pushad

.redirect:
    ; Get fn_read from filesystem pointed to by file
    mov     ebx,                [ebp - 4]
    mov     ebx,                [ebx + GenericFile.filesystem]
    mov     eax,                [ebx + GenericFilesystem.fn_read]

    mov     ebx,                [ebp - 4]
    mov     ecx,                [ebp - 8]
    mov     edx,                [ebp - 12]
    mov     edi,                [ebp - 16]

    push    ebp
    mov     ebp,                esp
    push    ebx                                 ; file
    push    ecx                                 ; offset
    push    edx                                 ; buffer
    push    edi                                 ; num_bytes
    call    eax
    mov     esp,                ebp
    pop     ebp

.epilog:
    popad
    ret



; write_file:
;   
;
; Arguments (4):
;   [FURTHEST FROM EBP]
;     3.  u32                                   num_bytes
;     2.  ptr32<u8>                             source
;     1.  u32                                   offset
;     0.  ptr32<GenericFile>                    file
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
write_file:
.prolog:
    pushad

.check_function_pointer:
    mov     ebx,                [ebp - 4]
    mov     ebx,                [ebx + GenericFile.filesystem]
    mov     eax,                [ebx + GenericFilesystem.fn_write]

    cmp     eax,                0
    je      .epilog

.redirect:
    mov     ebx,                [ebp - 8]
    mov     ecx,                [ebp - 8]
    mov     edx,                [ebp - 12]
    mov     edi,                [ebp - 16]

    push    ebp
    mov     ebp,                esp
    push    ebx                                 ; file
    push    ecx                                 ; offset
    push    edx                                 ; source
    push    edi                                 ; num_bytes
    call    eax
    mov     esp,                ebp
    pop     ebp

.epilog:
    popad
    ret
