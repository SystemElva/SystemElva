
; DO NOT INCLUDE OTHER FILES HERE; DO THAT AT THE BOTTOM OF THIS FILE

bits 16
org 0xa000

stage2_start:
.setup_stack:
    mov ebx, 0x800
    mov ss, ebx
    mov ebp, 0x2000
    mov esp, ebp

    sub esp, 256
    mov esi, esp

    ; Save the origin disk identifier
    mov [esi], dx

    ; Reset display
    mov ah, 0x00
    mov al, 0x03
    int 0x10

.initialize:
    mov [SECTOR_STACK_HEIGHT], word 0

.load_partition:
    mov eax, esi
    add eax, (256 - 16)

    push ebp
    mov ebp, esp
    push eax
    push word [esi]
    push word 1
    call disk_open_partition
    mov esp, ebp
    pop ebp

    ; Save the pointer to the partition reader
    mov [esi + 4], eax

    push dword text.no_boot_partition
    jmp crash_with_text

.load_fat12_filesystem:

    cli
    hlt

.unimplemented:
    push dword text.unimplemented
    jmp crash_with_text



%include "all.asm"

