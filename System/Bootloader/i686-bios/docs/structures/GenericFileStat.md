# Generic File Stat | ElvaBoot i686

## C-Definition

A less thorough  explanation of the structure's memory layout, without
explanation of the fields' contents.

```C
enum GenericFileType
{
    GENERIC_FILE_TYPE_INVALID = 0,
    GENERIC_FILE_TYPE_REGULAR = 1,
    GENERIC_FILE_TYPE_FOLDER = 2,

    // From here on only for completeness

    GENERIC_FILE_TYPE_PIPE = 3,
    GENERIC_FILE_TYPE_CHARACTER_DEVICE = 4,
    GENERIC_FILE_TYPE_BLOCK_DEVICE = 5,
    GENERIC_FILE_TYPE_SOCKET = 6,

    GENERIC_FILE_TYPE_SMYBOLIC_LINK = 16, // 1 << 4
};

struct GenericFileStat
{
    unsigned char stat_version;
    unsigned char file_type;
    unsigned short permissions;
    unsigned int owner;
    unsigned int group;
    unsigned int length;

    char reserved[48];
};
```

> More documentation about `enum GenericFileType` can be  found in the
> [Generic File documentation](./GenericFile.md#generic-file-type).

## Thorough Definition

|  Index  |  Offset  |  Length  |  Type       |  Field Name          |
|-------  | -------- | -------- | ----------- | -------------------- |
|  0      |  0x00    |  4       |  Uint8      |  `stat_version`      |
|  1      |  0x04    |  4       |  Uint8      |  `file_type`         |
|  2      |  0x08    |  4       |  Uint16     |  `permissions`       |
|  3      |  0x0c    |  4       |  Uint32     |  `owner`             |
|  4      |  0x10    |  4       |  Uint32     |  `group`             |
|  5      |  0x14    |  4       |  Uint32     |  `length`            |
|  6      |  0x18    |  48      |             |  `reserved`          |

0. `stat_version: Uint8`  
    Version of the stat structure. The current version  is `1`. When a
    new version is made, the old documentation should stay available.

1. `file_type: Uint8`  
    General Type of  the file entry; whether  this is a  regular file,
    folder or  one of  the other entry  types that are  documented the
    [Generic File documentation](./GenericFile.md#generic-file-type).

2. `permissions: Uint16`  
    Permissions on reading, writing and executing the file. These are
    split into three parts: Owner, Group and Others.

    Bit Description (Bit 0 is the lowest-significance bit):

    |  Index  |  First Bit  |  Bit Count  | Field Name               |
    | ------- | ----------- | ----------- | ------------------------ |
    |  0      |  0          |  3          | `owner`                  |
    |  1      |  3          |  3          | `group`                  |
    |  2      |  6          |  3          | `others`                 |

    The inner structure is the same for all three of of those. The
    Bit Description is as follows (Bit 0 is the lowest-significance bit):

    |  Index  |  First Bit  |  Bit Count  | Field Name               |
    | ------- | ----------- | ----------- | ------------------------ |
    |  0      |  0          |  1          | `execute`                |
    |  1      |  1          |  1          | `write`                  |
    |  2      |  2          |  1          | `read`                   |

3. `owner: Uint32`  
    Identifier of  the file's owner. This is 0 if  the filesystem does
    not support file ownership or  if it stores the information  in an
    incompatible way.

4. `group: Uint32`
    Identifier of the group which has  *some* access to the file. More
    information  about the  exact type of  access can be found  in the
    `permissions` - field.

5. `length: Uint32`  
    Length of the file, in bytes.

6. `reserved`  
    Bytes reserved for future use. These should be zeroed out.

