# Result | ElvaBoot i686

The result structure described in this documentation is used to convey
information about a procedure's  status, whether it succeeded with the
result value added to it. The idea is similar to the Result-value Rust
supports, though the implementation differs strongly.

This structure is supposed to be  used by giving a procedure a pointer
to a memory area  of 16 bytes, ideally  one on  the stack  (within the
stack frame of the caller).

## C-Definition

A less thorough  explanation of the structure's memory layout, without
explanation of the fields' contents.

```C
enum StatusCode
{
    STATUS_SUCCESS                  = 0,

    // Invalid Argument Error Range:     [ 0x0010 .. 0x0fff ]
    // Function-interal Error Range:     [ 0x1000 .. 0x1fff ]
    // Subordinate Function Error Range: [ 0x2000 .. 0xffef ]

    STATUS_UNKNOWN_ERROR            = 0xfffe,
    STATUS_UNKNOWN_CRITICAL_FAILURE = 0xffff,
};

/// @brief Up to three return values with one 16-bit status code.
/// @note
///     - Size: 16 Bytes
struct Result
{
    unsigned short status_code;
    unsigned short num_values;
    unsigned int immediate[3];
};
```

## Thorough Definition

|  Index  |  Offset  | Length |  Type       |  Field Name            |
|-------  | -------- | ------ | ----------- | ---------------------- |
|  0      |  0       |  2     |  u16        |  `status_code`         |
|  1      |  2       |  2     |  u16        |  `num_values`          |
|  2      |  4       |  12    |  u32        |  `immediate`           |
|  *      |  0       |  16    |             |  TOTAL                 |

The below list explains the values' usage more thoroughly:

0. `status_code: u16`  
    A status code, as defined by the function. If this is anything but
    zero, the `immediate` field may not contain any return values; the
    first of its  elements may contain a log  entry number, though. If
    it doesn't contain a log entry  number, it must be zero, as all of
    the other unused values.

1. `num_values: u16`  
    Number of values of `immediate` used. If  this indicates more than
    three values, `immedate[2]`  (zero-indexed) must contain a pointer
    to the remaining values.

2. `immediate: [3]u32`  
    Three directly encoded 4-byte values to be used by the callee in a
    way defined  by the function itself.  Most sensible to  be used as
    return values.  All  values not used by the callee  must be set to
    zero by the callee.

