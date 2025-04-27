
; 512 bytes before the sector stack's bottommost entry.
RAW_DISK_READ_ADDRESS equ (SECTOR_STACK_START - 512)

RAW_DISK_READ_OFFSET equ (RAW_DISK_READ_ADDRESS & 0xf)
RAW_DISK_READ_SEGMENT equ (RAW_DISK_READ_ADDRESS >> 4)

MBR_PARTITION_LIST_START equ 0x01be

; disk_open_partition:
;   Open a partition and write the result value to the given buffer.
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  u16                           partiton_index
;     1.  u16                           disk_id
;     0.  ptr32<PartitionReader>        partition_reader
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
disk_open_partition:
.prolog:
    pushad
    sub     esp,                16
    mov     esi,                esp

.load_mbr_sector:
    ; Prepare disk address packet
    mov     [esi],              word 0x10       ; Length of DAP
    mov     [esi + 2],          word 1          ; Number of sectors
    mov     [esi + 4],          word RAW_DISK_READ_OFFSET   ; Output Offset
    mov     [esi + 6],          word RAW_DISK_READ_SEGMENT  ; Output Segment
    mov     [esi + 8],          dword 0         ; Lower part of LBA
    mov     [esi + 12],         dword 0         ; Upper part of LBA

    ; Call the disk service interrupt
    mov     ah,                 0x42
    mov     dl,                 [ebp - 6]
    int     0x13

.calculate_entry_address:
    xor     edi,                edi
    mov     di,                 [ebp - 8]
    shl     edi,                4
    add     edi,                MBR_PARTITION_LIST_START + RAW_DISK_READ_ADDRESS,

.copy_mbr_info:
    mov     ebx,                [ebp - 4]

    ; Partition's First LBA
    mov     edx,                [edi + 8]
    mov     [ebx],              edx

    ; LBA count
    mov     edx,                [edi + 12]
    mov     [ebx + 0x04],       edx

    ; Partition Type
    mov     dl,                 [edi + 4]
    mov     [ebx + 0x08],       dl

.copy_argument_info:
    ; Disk Identifier
    mov     dl,                 [ebp - 6]
    mov     [ebx + 0x09],       dl

    ; Partition Index
    mov     dl,                 [ebp - 8]
    mov     [ebx + 0x0a],       dl

.epilog:
    add     esp,                16
    popad
    ret



; disk_read_sector:
;   Read a sector at a given index within a given partiton.
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  u32                           sector_index
;     1.  ptr32<[512]u8>                output_buffer
;     0.  ptr32<PartitionReader>        partition_reader
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
disk_read_sector:
.prolog:
    pushad
    sub     esp,                16
    mov     esi,                esp

.load_mbr_sector:
    ; Get Sector Index
    mov     ebx,                [ebp - 4]       ; Get partition
    mov     eax,                [ebx]           ; Partition's first LBA
    add     eax,                [ebp - 12]      ; Add offset within partition

    ; Get Memory Buffer Segment:Offset
    mov     ecx,                [ebp - 8]
    and     cx,                 0x0f
    mov     ebx,                [ebp - 8]
    shr     bx,                 4

    ; Prepare disk address packet
    mov     [esi],              word 0x10       ; Length of DAP
    mov     [esi + 0x02],       word 0x01       ; Number of sectors
    mov     [esi + 0x04],       cx              ; Memory Buffer Offset
    mov     [esi + 0x06],       bx              ; Memory Buffer Segment
    mov     [esi + 0x08],       eax             ; Lower part of LBA
    mov     [esi + 0x0c],       dword 0         ; Upper part of LBA

    mov     ebx,                [ebp - 0x04]    ; Get partition
    mov     dl,                 [ebx + 0x09]    ; Get disk identifier

    ; Call the disk service interrupt
    mov     ah,                 0x42
    int     0x13

.epilog:
    add     esp,                16
    popad
    ret

%include "disk/sector_stack.asm"
