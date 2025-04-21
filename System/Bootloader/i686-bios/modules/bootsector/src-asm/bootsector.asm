
PARTITION_IDENTIFIER equ 0x9e

bits 16
org 0x7c00
entry:
    mov bx, 0x7e00
    mov ss, bx
    mov bp, 512
    mov sp, 512
    push dx

    push bp
    mov bp, sp
    call find_partition
    mov sp, bp
    pop bp

    cmp ax, 0xff
    je display_error.partition_not_found

    pop dx
    push bp
    mov bp, sp
    push ax
    push dx
    call load_partition
    mov sp, bp
    pop bp

    jmp jump_to_partition

find_partition:
    xor si, si
.finder_loop:
    mov ax, si
    shl ax, 4
    add ax, (0x7c00 + 446)
    mov bx, ax
    add bx, 4
    cmp [bx], byte PARTITION_IDENTIFIER
    je .partition_found
    inc si
    cmp si, 4
    jb .finder_loop
.partition_not_found:
    mov ax, 0xff
    ret
.partition_found:
    mov ax, si
    ret



; Arguments:
; FURTHEST FROM BP
; 4) Start LBA, less significant half
; 3) Output Segment
; 2) Output Offset
; 1) Disk ID 
; NEAREST TO BP
load_sector:
    pusha

    ; Allocate Disk Address Packet
    sub sp, 16
    mov bx, sp
    mov [bx], byte 0x10     ; Length of DAP
    mov [bx + 1], byte 0    ; Unused byte
    mov [bx + 2], word 1    ; Sector count

    ; Write offset of the output buffer
    mov ax, [bp - 4]
    mov [bx + 4], ax

    ; Write segment of the output buffer
    mov ax, [bp - 6]
    mov [bx + 6], ax

    ; Write LBA of sector to read
    mov si, [bp - 8]
    mov [bx + 8], si
    mov [bx + 10], word 0
    mov [bx + 12], dword 0

    ; Perform the interrupt
    mov si, bx
    mov dl, [bp - 2]
    mov ah, 0x42            ; Extended Read from sectors
    int 0x13

    add sp, 16
    popa
    ret



load_partition:
    sub sp, 16
    mov di, sp
    mov [di], word 0 ; Sector Index

    ; Store the start sector
    mov bx, [bp - 2]            ; Partition Index
    shl bx, 4                   ; Get the offset from the MBR-table's tsart
    add bx, (0x7c00 + 446)      ; Point into MBR table
    mov [di + 2], bx            ; Partition Table Entry Pointer
    mov ax, [bx + 8]
    mov [di + 4], ax            ; Lower Partition Start LBA
    mov ax, [bx + 10]
    mov [di + 6], ax            ; Higher Partition Start LBA

    mov ax, [bx + 12]
    mov [di + 8], ax            ; Lower Partition Sector Count
    ; mov ax, [bx + 6]
    ; mov [di + 10], ax           ; Higher Partition Sector Count

.loader_loop:
    mov bx, [di]        ; Sector Index
    mov dx, [bp - 4]    ; Disk Identifier

    ; Segment Address
    mov cx, [di]
    shl cx, 5
    add cx, 0x0a00
    ; mov ax, [di]
    ; shl ax, 4
    ; sub cx, ax
    mov bx, 0

    push bp
    mov bp, sp
    push dx
    push bx
    push cx
    mov ax, [di + 4]
    add ax, [di]
    push ax
    call load_sector
    mov sp, bp
    pop bp

    mov ax, [di]
    cmp ax, [di + 8]

    ; Increment and write-back the sector index.
    inc ax
    mov [di], ax
    
    jb .loader_loop
.finished:
    add sp, 16
    ret


jump_to_partition:
    jmp 0xa000
    cli
    hlt



display_error:
.partition_not_found:
    mov si, .partition_not_found_text
    jmp .write_text
.partition_not_found_text:
    db "Failed finding Partition!", 0x00

; SI: Text-Address
.write_text:
    ; Reset Display
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    xor di, di
.text_writer_loop:
    ; Move Cursor
    mov ah, 0x02    ; Interrupt Function (move cursor)
    mov bh, 0       ; Display Page
    mov dx, 3       ; Start Column
    add dx, di
    mov dh, 2       ; Line
    int 0x10

    ; Gather character and check if it is the null-terminator.
    mov bx, si
    add bx, di
    mov al, [bx]
    cmp al, 0x00
    je .halt

    ; Display the character
    mov ah, 0x0a
    mov bh, 0
    mov cx, 1
    int 0x10

    inc di
    jmp .text_writer_loop

.halt:
    cli
    hlt

times 446 - ($ - $$) nop

loader_partition:
    db 0x80
    db 0x00, 0x00, 0x00
    db PARTITION_IDENTIFIER
    db 0x00, 0x00, 0x00
    dd 1
    dd 63

system_partition:
    db 0x80
    db 0x00, 0x00, 0x00
    db 1 ; FAT12 partition ID
    db 0x00, 0x00, 0x00
    dd 64
    dd 1024

times 510 - ($ - $$) db 0x00
db 0x55, 0xaa

