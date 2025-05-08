
; fat12_file_statistics:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     3.  u32                                   len_path_buffer
;     2.  ptr32<char>                           utf8_path_buffer
;     1.  ptr32<Fat12FileStat>                  statistics_buffer
;     0.  ptr32<Fat12File>                      file
;   [NEAREST TO EBP]
;
; Return Value:
;   - [EAX]:    Length of the path
fat12_get_file_statistics:
.prolog:
    pushad

.search_file:

.epilog:
    popad
    ret
