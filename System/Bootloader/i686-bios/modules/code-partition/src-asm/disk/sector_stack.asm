; For an explanation of the concept of a sector stack, look into the
; code-partition's documentation, in the file "SectorStack.md".



SECTOR_STACK_START    equ (0xa000 + (33 * 512))
SECTOR_STACK_HEIGHT   equ (0xa000 + (31 * 512) + 510)
SECTOR_STACK_CAPACITY equ 16

; disk_push_sector:
;   Loads a single sector from a given sector index at a partition
;   onto the sector stack and returns the pointer to the data.
;
; Arguments (2):
;   [FURTHEST FROM EBP]
;     1.  U32       sector_index        (Within Partition)
;     0.  Ptr32     partition_reader    (32 bytes)
;   [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Pointer to the sector or NULL on failure.
disk_push_sector:
.prolog:
    pushad

.calculate_address:
    cmp word [SECTOR_STACK_HEIGHT], SECTOR_STACK_CAPACITY
    jae .sector_stack_exceeded

    ; Get stack height in bytes
    xor eax, eax
    mov ax, word [SECTOR_STACK_HEIGHT]
    shr eax, 9

    ; Point onto stack
    add eax, SECTOR_STACK_START
    mov [esp + 28], eax ; Save the value as return value

    mov ecx, [ebp - 4]
    mov ebx, [ebp - 8]

    push ebp
    mov ebp, esp
    push ecx
    push eax
    push ebx
    call disk_read_sector
    mov esp, ebp
    pop ebp

    jmp .epilog

.sector_stack_exceeded:
    mov [esp + 28], dword 0

.epilog:
    popad
    ret




; disk_pop_sector:
;   Shrinks the sector stack by a given amount of sectors.
;
; Arguments (1):
;   [FURTHEST FROM EBP]
;     0.  U16       num_sectors
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
disk_pop_sector:
.prolog:
    push ax

.subtract:
    mov ax, [ebp - 2]
    sub [SECTOR_STACK_HEIGHT], ax

.epilog:
    pop ax
    ret

