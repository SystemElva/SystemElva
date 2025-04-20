# Bootloader

The bootloader of SystemElva. It searchs the disk for a FAT filesystem
for loading that contains the kernel, loads it,  giving it  some basic
data about the system as arguments.

## Project Structure

The root  directory contains the folders for the different  bootloader
distributions (i386, i686-bios,  x86_64-bios, x86_64-uefi, et cetera).

Within each of those distributions  folders (of which i686 is the only
one  planned  for the  near  future), there  always are  the following
folder items:

- `.build/` \*  
    Intermediate files used in the build process.

- `.out/` \*  
    Contains the finished build results, test executables and, in a
    sub-directory, memory dumps.

- `assets/` (optional)  
    Contains asset files for the scripts and for the build process.

- `modules/` (source code)  
    Contains the  source code  of the  distribution. The  modules  are
    hard-coded; adding a new one involves modifying the build scripts.
    Each module contains a source folder named as `src-$LANGUAGE`, for
    example  `src-asm/`, `src-zig/`, `src-c/` or for  C header  files:
    `inc-c`.  Furthermore,  the module  may  include  the  development
    documentation in a folder called `docs/`.

- `src-sh/` (optional)  
    If the  build process  is more  involved, justifying a  split into
    more than one file, this folder contains those shell scripts.

- `do.sh`  
    Main script  for building / running the bootloader and dumping the
    memory of the instance currently emulated by QEMU.

> Folder items marked with an  asterisk (\*) are internal, i.e. listed
> in the `.gitignore` and supposed to be used by the build system.

