
FAT12_LOGICAL_SECTORS_PER_CLUSTER   equ 0x0d
FAT12_NUM_RESERVED_SECTORS          equ 0x0e
FAT12_FAT_COUNT                     equ 0x10
FAT12_MAXIMUM_RDR_ENTRIES           equ 0x11
FAT12_LOGICAL_SECTORS_PER_FAT       equ 0x16

; fat12_open_filesystem:
;   Open a partition as a FAT12-filesystem.
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     1.  ptr32<Fat12Filesystem>                filesystem_buffer
;     0.  ptr32<Partition>                      partition
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
fat12_open_filesystem:
.prolog:
    pushad

.set_function_pointers:
    mov ebx, [ebp - 8] ; Get filesystem buffer
    mov [ebx], dword fat12_open_file
    mov [ebx + 4], dword fat12_close_file
    mov [ebx + 8], dword fat12_read_file
    mov [ebx + 12], dword 0
    mov [ebx + 16], dword fat12_get_file_statistics

.set_argument_data:
    mov eax, [ebp - 4]
    mov [ebx + 32], eax

.load_filesystem:
    ; Load the first sector of the filesystem
    push ebp
    mov ebp, esp
    push eax
    push dword 0
    call disk_push_sector
    mov esp, ebp
    pop ebp

.calculate_root_directory_start:
    mov ecx, eax
    xor eax, eax
    xor edx, edx

    ; Gather the data to calculate the sectors taken up by the FATs.
    mov al, [ecx + FAT12_LOGICAL_SECTORS_PER_CLUSTER]
    mov [ebx + 0x2b], al
    mov ax, [ecx + FAT12_LOGICAL_SECTORS_PER_FAT]
    mov dl, [ecx + FAT12_FAT_COUNT]

    ; Save the values (the FAT12 filesystem structure needs those)
    mov [ebx + 0x28], ax
    mov [ebx + 0x2a], dl

    ; Multiply the FAT size (EAX) with the number of FATs (EDX)
    mul edx

    xor edx, edx    ; Clear the remainder

    ; Add the reserved sectors on top
    mov dx, [ecx + FAT12_NUM_RESERVED_SECTORS]
    add eax, edx

    mov [ebx + 0x24], eax

.finish:
    push ebp
    mov ebp, esp
    push word 1
    call disk_pop_sectors
    mov esp, ebp
    pop ebp

.epilog:
    popad
    ret
