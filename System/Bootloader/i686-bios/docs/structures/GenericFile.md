# Generic File | ElvaBoot i686

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

struct GenericFile
{
    struct GenericFilesystem *filesystem;
    unsigned int flags;
    char padding[8];
    char specifics[16];
};
```

> For more information about `enum GenericFileType`, it is advisable
> to consult [the appropriate section](#generic-file-type).

> For the explanation on why  the `enum GenericFileType` is structured
> the way it is, see: [here](#symbolic-links).

## Thorough Definition

|  Index  |  Offset  |  Length  |  Type       |  Field Name          |
|-------  | -------- | -------- | ----------- | -------------------- |
|  0      |  0x00    |  4       |  Pointer32  |  `filesystem`        |
|  1      |  0x04    |  4       |  Uint32     |  `flags`             |
|  2      |  0x08    |  8       |             |  `padding`           |
|  3      |  0x10    |  16      |  Unknown    |  `specifics`         |

0. `filesystem: Pointer32`  
    Pointer to  the [generic filesystem](./GenericFilesystem.md).  The
    generic filesystem contains the function pointers which are called
    by filesystem abstraction functions.

1. `flags: Uint32`  
    Bitfield information describing basic details of a file.

    Bit Description (Bit 0 is the lowest-significance bit):

    |  Index  |  First Bit  |  Bit Count  | Field Name               |
    | ------- | ----------- | ----------- | ------------------------ |
    |  0      |  0          |  1          | `valid`                  |
    |  1      |  1          |  5          | `entry_type`             |
    |  2      |  6          |  1          | `readable`               |
    |  3      |  7          |  1          | `writable`               |
    |  4      |  8          |  1          | `executable`             |

    0. `valid`  
        Should always be present. This bit not being set signals that
        an error has occurred in the file opening procedure.

    1. `entry_type`  
        Type of the file entry (regular file, directory, et cetera).
        For more information, see [here](#generic-file-type).

    2. `readable`  
        Whether the permissions currently allow reading from the file.

        0 = Not Allowed  
        1 = Allowed  

    3. `writable`  
        Whether the file is  currently allowed to  be written to. This
        does not  indicate whether  it can be  written to. Even if the
        permission is correct, the driver  still may not support write
        operations.

        0 = Not Allowed  
        1 = Allowed  

    4. `executable`  
        Whether the file can be executed with current permissions.

        0 = Not Allowed  
        1 = Allowed  

2. `padding`  
    Eight bytes for alignment and future expansion. It is advisable to

    leave this as zeroes as the meaning may change in the future.
3. `specifics`  
    Space to be  used by the filesystem  driver to store  pointers and
    other information for file identification.

### Generic File Type

The list below lists all `enum GenericFileType` - values and  explains
their usage for completeness.

- Invalid Entry: 0  
    Written on error or in conjunction with symbolic links.

- Regular File: 1  
    File record used to linearly store bytes.

- Folder : 2  
    Folder / Directory; a container for more files / folders.

- Pipe (FIFO): 3  
    Only for completeness.

- Character Device: 4  
    Only for completeness.

- Block Device: 5  
    Only for completeness.

- Socket: 6  
    Only for completeness.

- Symbolic Link ([note](#symbolic-links))  
    For symbolic  links to folder  entries,  the uppermost of the five
    bits should be set high (1). If the target isn't known or if it is
    irrelevant, the  rest of the  bits are  allowed to  be zeroed  out
    without counting as an *Invalid Entry*.

### Symbolic Links

The `enum GenericFileType` may seem a little odd. This is because of a
deliberalte design  decision. The  symbolic link - bit  can be toggled
on while keeping all other bits intact; the file entry thus isn't only
a "symbolic link",  but a "symbolic link to *X*", where *X* can be any
of the other values of `enum GenericFileType`.

