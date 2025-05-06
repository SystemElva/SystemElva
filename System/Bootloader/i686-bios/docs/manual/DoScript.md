# `do.sh` | ElvaBoot i686

The `do.sh` - script is the main interaction point with the build and
test infrastructure of the  *ElvaBoot i686*  bootloader. It can build
the bootsector and  code partition, generate a  rudimentary image and
build and run the tests that the software provides.



## Building

The run-time part of the project can be built like this:

```sh
./do.sh fs      # Optionally create the bootfs
./do.sh b
```

Note that the creation of the boot filesystem is only optional because
the build-action does it if it hasn't been done before.



## Testing

The tests can be built and run like this:

```sh
./do.sh bt      # Build tests
./do.sh rt      # Run tests
```

> Before being able to build the tests, the *boot fs* has to be turned
> into an images and the main sources have to be assembled.

The rest of this section will explain the options that can be given to
the different actions involving tests.

### Action: `build-tests` or `bt`

Builds all tests of one or  multiple modules and puts them into folder
for that specific build, which can potentially have a label. The test
builds reside in `.tests/builds`.

####  `-m` or `--modules`

Comma-separated list of modules  of which to build all tests. This can
also be only one  module. If this isn't given, it  will only build the
tests of the `code-partition` - module.

#### `-bl` or `--build-label`

Gives the build a name. This name  won't be the folder name within the
`tests/` - folder, it will only be stored in the test build inside the
`build_config.ini`. The label will  be shown by `list-test-builds`. If
this isn't given, the current date  and time will be used, in a format
going from the least precise component to the most precise one, as in:
`YYYY-mm-DD.HH-MM-SS`, where:

-  `YYYY` is the year
- `mm` is the number of the month
- `DD` is the number of the day
- `HH` is the 24-hour - style hour of the day
- `MM` is the minute within the hour
- `SS` is the second.

### Action: `run-tests` or `rt`

Run some or all  suites of a specified test build. The  test build can
be specified by its label, its index (with a higher index meaning that
the build is  older) or not  specified at all, which  will execute the
newest test that has been created.

This action accepts the following options:

- `-s` or `--suites`
- `-i` or `--index`
- `-bl` or `--build-label`

#### `-i` or `--index`

Index of the test to execute. The index can be gotten from running the
`list-test-builds` - action.

> If label is given after the index, the label overrides the index.

#### `-bl` or `--build-label`

Searches for  the build with  a specific label  and executes  the test
build, if one was found.

> If an index is given after the label, the index overrides the label.

#### `-s` or `--suites`

A comma-separated  list of test suites  that should be  executed. If a
test suite that couldn't be found is given, a warning is displayed but
the process continues with the following suites.

### Action: `build-and-run-tests` or `brt`

Creates a new test build and runs it immediately.

> This action is still `@todo`!

### Action: `list-test-builds` or `lt`

Shows a table of test builds that have  been created before. The first
row of the table contains the  index which can be used for running the
suites of this build. A higher index means that the build is older. 



## Cleaning Up

Because all old  images and all  old test builds are  being preserved,
there are two main actions to clean up all the binary data created by
the other actions and one action to unify them both.

### Action: `cleanup` or `c`

Removes the object files of the *code partition* and *bootsector*, the
image of the *boot fs* and deletes all disk images in `.out/`.

### Action: `cleanup-tests` or `ct`

Removes all  test builds and test  instances. This doesn't  remove any
logs, as logs typically  aren't too big and may prove useful later on.

### Action: `cleanup-all` or `ca`

Internally, this calls the  script behind `cleanup-tests` and then the
script behind `cleanup`.

