
FAT12_DIRENT_ATTRIBUTES         equ 0x0b
FAT12_DIRENT_FILE_SIZE          equ 0x1c
FAT12_DIRENT_FIRST_CLUSTER      equ 0x1a

fat12_text:
.long_file_names_unimplemented:
    db "FAT12 Long File names aren't implemented (yet)!", 0x00

.marker_1:
    db "Marker 1", 0x00
