
; fat12_read_file:
;   
;
; Arguments (4):
;   [FURTHEST FROM EBP]
;     3.  u32                                   num_bytes
;     2.  ptr32<u8>                             buffer
;     1.  u32                                   offset
;     0.  ptr32<Fat12File>                      file_buffer
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
fat12_read_file:
.prolog:
    pushad

.search_file:

.epilog:
    popad
    ret
