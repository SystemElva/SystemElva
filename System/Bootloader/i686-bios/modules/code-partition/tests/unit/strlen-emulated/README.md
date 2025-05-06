# `strlen` Test | ElvaBoot

This document explains  how to build, use and modify the  tests of the
ElvaBoot test for its `strlen` utility function.

## Building

The test is normally built by the `build_tests.sh` - script. When it's
built, the image will be put into the i686-bootloader's folder at:
`.tests/code-partition/strlen.img`.

## Using

Execute this from inside the `i686-bios`-folder:

```
qemu-system-i386 .tests/code-partition/strlen.img
```

If the emulated system's screen turns green with the text "Correct" on
it, the test  succeeded. In the case that it turns  red with "Invalid"
written onto it, it failed.

## Adding Cases

Each line in the `test_cases.txt` is considered a  test case. Assembly
code for it is  automatically generated at `generated_test_cases.asm`.

