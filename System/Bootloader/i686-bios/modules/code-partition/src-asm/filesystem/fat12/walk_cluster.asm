
struc       Fat12ClusterChainWalker

    .fn_load                    resd 1
    .first_cluster              resd 1
    .cluster_table_index        resd 1
    .chain_item_index           resd 1
    .filesystem                 resd 1
    .reader_buffer              resd 1

endstruc



; fat12_walk_cluster_chain:
;   
;
; Arguments (3):
;   [FURTHEST FROM EBP]
;     0.  ptr32<Fat12ClusterChainWalker>        file
;   [NEAREST TO EBP]
;
; Return Value:
;   N/A
fat12_walk_cluster_chain:
.prolog:
    pushad

.search_file:

.epilog:
    popad
    ret
