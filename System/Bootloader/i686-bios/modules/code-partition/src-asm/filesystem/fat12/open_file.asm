
; fat12_open_file:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     2.  ptr32<char>                           utf8_path
;     1.  ptr32<Fat12File>                      file_buffer
;     0.  ptr32>Fat12Filesystem>                filesystem
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
fat12_open_file:
.prolog:
    pushad

.search_file:
    push dword [ebp - 12]
    jmp dword crash_with_text

.epilog:
    popad
    ret
