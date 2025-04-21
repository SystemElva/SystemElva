
SECTOR_READER_BUFFER equ (0xa000 + 31 * 512)
MBR_PARTITION_LIST_START equ 0x01be

; disk_open_partition:
;   
;
; Arguments (8):
;   [FURTHEST FROM EBP]
;     2.  U16       partiton_index
;     1.  U16       disk_id             (Only lower byte used)
;     0.  Ptr32     partition_buffer    (32 bytes)
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
disk_open_partition:
.prolog:
    pushad
    sub esp, 16
    mov esi, esp

.load_mbr_sector:
    mov ecx, SECTOR_READER_BUFFER
    and ecx, 0x0f

    mov ebx, SECTOR_READER_BUFFER
    shr ebx, 4

    ; Prepare disk address packet
    mov [esi], word 0x10        ; Length of DAP
    mov [esi + 2], word 1       ; Number of sectors
    mov [esi + 4], cx           ; Memory Buffer Offset
    mov [esi + 6], bx           ; Memory Buffer Segment
    mov [esi + 8], dword 0      ; Lower part of LBA
    mov [esi + 12], dword 0     ; Upper part of LBA

    ; Call the disk service interrupt
    mov ah, 0x42
    mov dl, [ebp - 6]
    int 0x13

.calculate_entry_address:
    xor edi, edi
    mov di, [ebp - 8]
    shl edi, 4
    add edi, MBR_PARTITION_LIST_START + SECTOR_READER_BUFFER

.copy_mbr_info:
    mov ebx, [ebp - 4]

    ; Partition's First LBA
    mov edx, [edi + 8]
    mov [ebx + 20], edx

    ; LBA count
    mov edx, [edi + 12]
    mov [ebx + 24], edx

    ; Partition Type
    mov dl, [edi + 4]
    mov [ebx + 28], dl

.copy_argument_info:
    ; Disk Identifier
    mov dl, [ebp - 6]
    mov [ebx + 29], dl

    ; Partition Index
    mov dl, [ebp - 8]
    mov [ebx + 30], dl

.epilog:
    add esp, 16
    popad
    ret

