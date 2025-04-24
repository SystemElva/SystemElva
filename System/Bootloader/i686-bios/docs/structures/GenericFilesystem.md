# Generic Filesystem | ElvaBoot i686

## C-Definition

A less thorough  explanation of the structure's memory layout, without
explanation of the fields' contents.

```C
struct GenericFilesystem
{
    unsigned int (*fn_read)(
        struct GenericFile *file,
        void *buffer,
        unsigned int len_buffer,
        unsigned int offset
    );

    unsigned int (*fn_write)(
        struct GenericFile *file,
        const void *data,
        unsigned int len_data,
        unsigned int offset
    );

    unsigned int (*fn_stat)(
        struct GenericFile *file,
        struct GenericFileStat *stat_buffer,
        char *path_buffer,
        unsigned int len_path_buffer
    );

    void (*fn_free)(
        struct GenericFile *file
    );

    void (*fn_destructor)(
        struct GenericFilesystem *filesystem
    );

    char padding[12];
    char specifics[32];
};
```

## Thorough Definition

|  Index  |  Offset  |  Length  |  Type       |  Field Name          |
|-------  | -------- | -------- | ----------- | -------------------- |
|  0      |  0x00    |  4       |  Pointer32  |  `fn_read`           |
|  1      |  0x04    |  4       |  Pointer32  |  `fn_write` *        |
|  2      |  0x08    |  4       |  Pointer32  |  `fn_stat`           |
|  3      |  0x0c    |  4       |  Pointer32  |  `fn_free` *         |
|  4      |  0x10    |  4       |  Pointer32  |  `fn_destruct` *     |
|  5      |  0x14    |  12      |             |  `padding`           |
|  6      |  0x20    |  32      |  Unknown    |  `specifics`         |

> Optional entries are marked with an asterisk (\*).

0. `fn_read: Pointer32`  
    Pointer to  a function  that reads  bytes from  a file  within the
    filesystem.

    Stack-provided Arguments:

    0. `file: Pointer32`  
        Pointer  to the  [generic file](./GenericFile.md) structure to
        read from.

    1. `buffer: Pointer32`  
        Address of the first byte of the space to which to write the
        data which will be read.

    2. `num_bytes: Uint32`  
        Number of bytes  to read into  the buffer. The buffer  must be
        able to hold this amount  of bytes, otherwise,  this action is
        unsafe. The functions have no way of validating this input.

        If `(offset + num_bytes) > len_file`,  the rest of  the buffer
        will be undefined (it won't be overwritten).

    3. `offset: Uint32`  
        Offset of the first byte of the file to read.

    Return Values:

    - `EAX`: Number of bytes read
        This can be smaller than the  `num_bytes`-argument if the file
        end was reached.

1. `fn_write: Pointer32` *  
    Pointer to a function that writes some data to a file.

    Stack-provided Arguments:

    0. `file: Pointer32`
        Pointer  to the  [generic file](./GenericFile.md) structure to
        write to.

    1. `data: Pointer32`

    2. `len_data: Uint32`

    3. `offset: Uint32`

    Return Values:

    - `EAX`: `written_bytes`, or `0xffffffff` on error.

2. `fn_stat: Pointer32`  
    Pointer to a  function used to  gather data  about a  folder item,
    like its length, type (file, folder, ...), full path, et cetera.

    Stack-provided Arguments:

    0. `file: Pointer32`  
        Pointer  to the  [generic file](./GenericFile.md) structure of
        which to get the information.

    1. `stat_buffer: Pointer32`  
        Pointer to the [generic file-stat](./GenericFileStat.md) which
        is supposed to be filled  by this function call. If  `NULL` is
        given, it  is assumed that only  the path is  wanted; it isn't
        considered an error.

    2. `path_buffer: Pointer32` or `NULL`  
        Pointer to the  memory to which to write the  full path of the
        specified file. The  string will be written  as UTF-8 and will
        be NUL-terminated, even if it's terminated by the buffer being
        too small. If `len_path_buffer` is 0, this is ignored.

    3. `len_path_buffer: Uint32`
        Length of the memory area of `path_buffer`.

    Return Values:

    - `EAX`: `len_path` or `0xffffffff` on error  
        Length of full path-string in bytes, including the terminating
        NUL character. This is the full string's length, not only what
        has actually been written! This only isn't returned on error.

3. `fn_free: Pointer32` *  
    Pointer to a function used to free a file entry and its memory.

    Stack-provided Arguments:

    0. `file`  
        The file which  is no longer needed and should  be freed. Note
        that calling this function makes the file unusable.

4. `fn_destruct: Pointer32` *  
    Frees the resources used up by the filesystem.

    Stack-provided Arguments:

    0. `filesystem: Pointer32`
        Pointer to the filesystem of which to free the working memory.
        The filesystem won't be usable after this has been called.

5. `padding`  
    Bytes used for alignment purposes. They  can contain anything, but
    to be safe for  the case of  later usage, they should initially be
    set to zero and not be touched thereafter.

6. `specifics`  
    Space for  information  used by  the actual,  specific  filesystem
    driver. This most likely is not the entirety of the memory used by
    any non-trivial driver.

