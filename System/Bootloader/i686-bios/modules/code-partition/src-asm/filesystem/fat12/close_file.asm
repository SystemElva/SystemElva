
; fat12_close_file:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     0.  ptr32<Fat12File>                      file
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
fat12_close_file:
.prolog:
    pushad

.free_resources:

.epilog:
    popad
    ret
