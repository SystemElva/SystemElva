# SystemElva

SystemElva is a hobbyist-grade  operating system, currently still in a
very early stage. It isn't supposed to be usable any time soon, though
it may be useful for learning purposes and for testing new concepts in
an operating system with a rather small codebase.

## Structure

- `Libraries/` *  
    Reusable components that could also work on other systems; are not
    specific to SystemElva and may be useful to other developers near
    the metal.

- `System/`  
    Contains the core  system components that will  be linked together
    to form the bootloader, kernel and to provide drivers.

    - [`Bootloader/`](System/Bootloader/README.md)  
        The ElvaBoot bootloader currently only has the goal to be able
        to boot the SystemElva-kernel (which is called `Galvan`).
    
    - `Drivers/` *  
        Separate drivers that  can be added to the system dynamically.
        They communicate with the  kernel using a stable syscall-based
        API and can be installed through moving into a special folder.

    - `Kernel/` *  
        The kernel (called Galvan) will reside in this directory.

    - `KernelDrivers/` *  
        A sub-directory containing the builtin drivers included in the
        kernel by default.

- `Tools/`  
    Tools that are made  to work on other systems,  made to be used by
    SystemElva (and possibly other systems) for building.

    - [`Machinize/`](Tools/Machinize/README.md)  
        An in-development assembler written in Zig.

    - `Reductor` *  
        Not yet in active development parser generator for prototyping
        and for simplifying the development process.

- `Userland/` *  
    User space applications to be able  to use the system in a command
    line interface. The shell interpreter will also go here.

> List items with  an asterisk (\*)  are only written  down until now;
> they may not exist yet or are in a very early stage.

## Roadmap

This section documents the roadmap of the SystemElva operating system.
Note that the points are not to be processed sequentially.

- ElvaBoot  
    - ElvaBoot i686-bios  
        The bootloader for Pentium II (and above) BIOS-based PCs.

        - [x] Bootsector  
        - [ ] A20 line check  
        - [x] Disk Sector Reader  
        - [x] Basic Memory Utilities  
        - [x] BootFS -creator  
        - [x] Data Structure Documentation  
        - [ ] FAT12 loader  
        - [ ] FAT16 loader  
        - [ ] FAT32 loader  
        - [ ] x86 Segmentation  
        - [ ] Kernel Loader  
        - [ ] Boot Protocol Specification  
        - [ ] Exposure of Boot Services  

- Machinize  
    An assembler made to be more  modern syntax-wise and provide a few
    more features for improved code structuring.

    - [x] Tokenizer  
    - [ ] Parser  
    - [ ] Validator  
    - [ ] 16-Bit Code Generator  
    - [ ] 32-Bit Code Generator  
    - [ ] Error Logger  
    - [ ] Configuration  
    - [ ] Documentation / Manual  
    - [ ] Specification  

- The Reductor  
    A parser generator for rapid prototyping of features for the shell
    language and other text-based  formats needed in the system. It is
    supposed to  be called  "The Reductor", not  only "Reductor";  the
    article is part of its name.

    - [ ] Tokenizer  
    - [ ] Parser  
    - [ ] Validator  
    - [ ] Zig Code Generator  
    - [ ] C Code Generator  
    - [ ] Machinize Code Generator
    - [ ] Error Logger  
    - [ ] Configuration  
    - [ ] Tests  
    - [ ] Documentation  
    - [ ] Specification  

- Galvan (Kernel)  
    The kernel still lays a far time  in the future; it doesn't make a
    lot of sense to create its roadmap at this point in time.
