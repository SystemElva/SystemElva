
text:
.unimplemented:
    db "Unimplemented Feature!", 0x00

.long_file_name_unimplemented:
    db "FAT12 LFN has't been implemented yet!", 0x00

.no_boot_partition:
    db "Failed finding the boot partition!", 0x00

.sector_stack_exceeded:
    db "Sector Stack exceeded!", 0x00

.config_path:
    db "/boot/elvaboot/config.json", 0x00

.true:
    db "True!", 0x00

.false:
    db "False!", 0x00

.long_file_name:
    db "Long File Name!", 0x00

.short_file_name:
    db "Short File Name!", 0x00

.boot_partition_filesystem_not_implemented:
    db "Filesystem of boot-partition has no built-in driver!", 0x00
