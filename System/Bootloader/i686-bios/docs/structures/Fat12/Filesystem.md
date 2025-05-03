# FAT12 Filesystem | ElvaBoot i686

The FAT12 filesystem structure described here is a representation in
the RAM that builds upon the `struct GenericFilesystem`.

## C-Definition

A less thorough  explanation of the structure's memory layout, without
explanation of the fields' contents.

```C
/// @brief Size: 96 bytes
struct Fat12Filesystem
{
    /// @brief Generic filesystem structure defined elsewhere.
    ///        Here, the focus is only on the FAT12-relevant data.
    char generic_filesystem[32];                // Offset; 0x00

    Partition *partition;                       // Offset; 0x20
    unsigned int root_directory_start;          // Offset; 0x24
    unsigned short root_directory_size;         // Offset; 0x28
    unsigned short fat_region_start;            // Offset; 0x2a
    unsigned short sectors_per_fat;             // Offset; 0x2c
    unsigned short fat_count;                   // Offset; 0x2e
    unsigned short data_region_start;           // Offset; 0x30
    unsigned short cluster_shift_value;         // Offset; 0x32
    unsigned char reserved[78];
};
```

## Thorough Definition

|  Index  |  Offset  | Length |  Type       |  Field Name            |
|-------  | -------- | ------ | ----------- | ---------------------- |
|  0      |  0x00    | 32     |             | `generic_filesystem`   |
|  1      |  0x20    | 4      |  ptr32      | `partition`            |
|  2      |  0x24    | 4      |  u32        | `root_directory_start` |
|  3      |  0x28    | 2      |  u16        | `root_directory_size`  |
|  4      |  0x2a    | 2      |  u16        | `fat_region_start`     |
|  5      |  0x2c    | 2      |  u16        | `sectors_per_fat`      |
|  6      |  0x2e    | 2      |  u16        | `fat_count`            |
|  7      |  0x30    | 2      |  u16        | `data_region_start`    |
|  8      |  0x32    | 2      |  u16        | `cluster_shift_value`  |
|  9      |  0x32    | 78     |             | `reserved`             |
|  *      |  0x00    | 128    |             | TOTAL                  |

0. `generic_filesystem`  
    [GenericFilesystem](../GenericFilesystem.md) structure, the header
    structure to the *Fat12Filesystem* - structure.

1. `partition: ptr32`  
    Pointer to  a [Partition](../Partition.md)  structure. the  reader
    for sectors. Must point to a valid FAT12 partition.

2. `root_directory_start" u32`  
    Index of the first  sector of the  root directory region, from the
    start of the partition.

3. `root_directory_size: u16`  
    Number of sections the root directory region encompasses.

4. `fat_region_start: u16`  
    First sector  of the FAT region, from  the start of the partition.
    This is equal to the reserved sector count in the FAT12 header.

5. `sectors_per_fat: u16`  
    Number of sectors per *File Allocation Table*. The entry count can
    be calculated by dividing through 1.5, throwing away the remainder
    because half entries aren't possible.

6. `fat_count: u16`  
    Number of  *File Allocation Table*s  of the  filesystem. Only  the
    first one will be used for the first few verisons.

7. `data_region_start: u16`  
    Number of sectors from the beginning  of the partition to the data
    region. This includes  the reserved  sectors, FAT region  and root
    directory region's sector count.

8. `cluster_shift_value: u16`  
    By how many bits one  must shift the cluster count  to the left to
    get the cluster's first sector, or  how much one must shift sector
    indices to the  right to get the cluster they  are contained in.  
    This is derived from FAT12's: *Logical sectors per cluster*-field.

9. `reserved`  
    Zeroes to fill up the [GenericFilesystem](../GenericFilesystem.md)
    structure. Shouldn't be set to any other values for future safety;
    this region might be used some day later.
