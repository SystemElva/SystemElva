
; 512 bytes before the sector stack's bottommost entry.
RAW_DISK_READ_BUFFER equ (SECTOR_STACK_START - 512)

MBR_PARTITION_LIST_START equ 0x01be

; disk_open_partition:
;   
;
; Arguments (3):
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
    ; Prepare disk address packet
    mov [esi], word 0x10        ; Length of DAP
    mov [esi + 2], word 1       ; Number of sectors
    mov [esi + 4], word (RAW_DISK_READ_BUFFER & 0xf)  ; Memory Buffer Offset
    mov [esi + 6], word (RAW_DISK_READ_BUFFER >> 4)  ; Memory Buffer Segment
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
    add edi, MBR_PARTITION_LIST_START + RAW_DISK_READ_BUFFER

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



; disk_read_sector:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  U32       sector_index        (Within Partition)
;     1.  Ptr32     output_buffer       (512 bytes)
;     0.  Ptr32     partition           (32 bytes)
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
disk_read_sector:
.prolog:
    pushad
    sub esp, 16
    mov esi, esp

.load_mbr_sector:
    ; Get Sector Index
    mov ebx, [ebp - 4]          ; Get partition
    mov eax, [ebx + 20]         ; Partition's first LBA
    add eax, [ebp - 12]         ; Add offset within partition

    ; Get Memory Buffer Segment:Offset
    mov cx, [ebp - 8]
    and cx, 0x0f
    xor ecx, ecx
    mov bx, [ebp - 8]
    shr bx, 4

    ; Prepare disk address packet
    mov [esi], word 0x10        ; Length of DAP
    mov [esi + 2], word 1       ; Number of sectors
    mov [esi + 4], cx           ; Memory Buffer Offset
    mov [esi + 6], bx           ; Memory Buffer Segment
    mov [esi + 8], eax          ; Lower part of LBA
    mov [esi + 12], dword 0     ; Upper part of LBA

    mov ebx, [ebp - 4]          ; Get partition
    mov dl, [ebx + 29]          ; Get partition number

    ; Call the disk service interrupt
    mov ah, 0x42
    int 0x13

.epilog:
    add esp, 16
    popad
    ret

%include "disk/sector_stack.asm"
