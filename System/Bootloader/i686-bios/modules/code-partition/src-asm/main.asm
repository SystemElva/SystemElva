
; DO NOT INCLUDE OTHER FILES HERE; DO THAT AT THE BOTTOM OF THIS FILE

bits 16
org 0xa000

stage2_start:
.setup_stack:
    mov     ebx,                0x800
    mov     ss,                 ebx
    mov     ebp,                0x2000
    mov     esp,                ebp

    sub     esp,                256
    mov     esi,                esp

    ; Save the origin disk identifier
    mov     [esi],              dx

    ; Reset display
    mov     ah,                 0x00
    mov     al,                 0x03
    int     0x10

.initialize:
    ; Setup the stack of loaded sectors.
    mov     [SECTOR_STACK_HEIGHT],              word 0

.load_partition:
    mov     edx,                esi
    add     edx,                (256 - (64 + 16))

    push    ebp
    mov     ebp,                esp
    push    edx
    push    word [esi]
    push    word 1
    call    disk_open_partition
    mov     esp,                ebp
    pop     ebp

.open_filesystem:
    mov ebx, esi
    add ebx, (256 - 128)

    push    ebp
    mov     ebp,                esp
    push    edx                                 ; Partition
    push    ebx                                 ; Buffer for filesystem
    call    open_filesystem
    mov     esp,                ebp
    pop     ebp

    cmp     eax,                0
    je      .unknown_filesystem

    mov     edx,                esi
    add     edx,                (256 - (128 + 16 + 32))

    push    ebp

    mov     ebp,                esp
    push    ebx                                 ; Filesystem
    push    edx                                 ; Buffer for file
    push    dword text.config_path              ; Path to file to load
    call    dword open_file
    mov     esp,                ebp
    pop     ebp

    cli
    hlt

.unimplemented:
    push    dword text.unimplemented
    jmp     crash

.unknown_filesystem:
    push    dword text.boot_partition_filesystem_not_implemented
    jmp     crash



%include "all.asm"
