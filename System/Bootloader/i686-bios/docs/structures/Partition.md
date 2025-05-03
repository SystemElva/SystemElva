# Partition | ElvaBoot i686

Representation of a partition. This currently is hardcoded to MBR/BIOS
disk systems, which is why it might change in the far future.

## C-Definition

A less thorough  explanation of the structure's memory layout, without
explanation of the fields' contents.

```C
struct Partition
{
    unsigned int first_lba;                     // Offset: 0x00
    unsigned int sector_count;                  // Offset: 0x04
    unsigned char type_id;                      // Offset: 0x08
    unsigned char disk_id;                      // Offset: 0x09
    unsigned char partition_index;              // Offset: 0x0a
    unsigned char reserved[5];
}
```

## Thorough Definition

|  Index  |  Offset  | Length |  Type       |  Field Name            |
|-------  | -------- | ------ | ----------- | ---------------------- |
|  0      |  0x00    |  4     |  u32        |  `first_lba`           |
|  1      |  0x04    |  4     |  u32        |  `sector_count`        |
|  2      |  0x08    |  1     |  u8         |  `type_id`             |
|  3      |  0x09    |  1     |  u8         |  `disk_id`             |
|  4      |  0x0a    |  1     |  u8         |  `partition_index`     |
|  *      |  0x00    |  16    |             |  TOTAL                 |

0. `first_Lba`  
    First Logical Block Address (LBA) of the represented partition.

1. `sector_count`  
    Number of sectors that the represented partition encompasses.

2. `type_id`  
    Identifier of the partition's  type, as read from the MBR. Further
    knowledge about that topic can  be obtained from the Wikipedia, in
    [this article](https://en.wikipedia.org/wiki/Partition_type).

3. `disk_id`  
    BIOS-provided identifier of the disk. This is the same value that
    is given to the bootsector in the `dl`-register.

4. `partition_index`  
    Index of the partiton in the partition table of the disk's MBR.
