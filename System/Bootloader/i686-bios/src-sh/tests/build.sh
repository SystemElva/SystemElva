#!/bin/bash

INVOCATION_PATH=$(pwd)
cd $(dirname $0)/../..
I686_PATH=$(pwd)

# Script Dependencies

INI="$I686_PATH/src-sh/ini.sh"

# Run-Time Constants (set once, used until the end)

START_TIME=$(date "+%Y-%m-%d.%H-%M-%S")

BOOTSECTOR_PATH=$I686_PATH/modules/bootsector
CODE_PARTITION_PATH=$I686_PATH/modules/code-partition
BOOT_FS_PATH=$I686_PATH/modules/bootfs

# Arguments (to be set in 'gather_arguments')

SPECIFIED_MODULES="code-partition"
BUILD_LABEL="$START_TIME"
SPECIFIED_TEST_TYPES="peek,unit"
INFORMATION_OUTPUT="/dev/stdout"
ERROR_OUTPUT="/dev/stderr"

gather_arguments() {
    local ACCEPT="ALL"
    for ARGUMENT in "$@"
    do
        case $ACCEPT in
            "ALL")
                if [[ "$ARGUMENT" == "-m" || "$ARGUMENT" == "--modules" ]];
                then
                    ACCEPT="MODULE-NAME"
                    continue
                fi

                if [[ "$ARGUMENT" == "-bl" || "$ARGUMENT" == "--build-label" ]];
                then
                    ACCEPT="BUILD-LABEL"
                    continue
                fi

                if [[ "$ARGUMENT" == "-t" || "$ARGUMENT" == "--test-types" ]];
                then
                    ACCEPT="TEST-TYPES"
                    continue
                fi

                if [[ "$ARGUMENT" == "-io" || "$ARGUMENT" == "--info-output" ]];
                then
                    ACCEPT="INFO-OUTPUT"
                    continue
                fi

                if [[ "$ARGUMENT" == "-eo" || "$ARGUMENT" == "--error-output" ]];
                then
                    ACCEPT="ERROR-OUTPUT"
                    continue
                fi



                if [[ "$ARGUMENT" == "-m="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-3))
                    SPECIFIED_MODULES=${ARGUMENT:3:$LEN_VALUE}
                    continue
                fi

                if [[ "$ARGUMENT" == "--modules="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-10))
                    SPECIFIED_MODULES=${ARGUMENT:10:$LEN_VALUE}
                    continue
                fi



                if [[ "$ARGUMENT" == "-t="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-3))
                    SPECIFIED_TEST_TYPES=${ARGUMENT:3:$LEN_VALUE}
                    continue
                fi

                if [[ "$ARGUMENT" == "--test-types="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-13))
                    SPECIFIED_TEST_TYPES=${ARGUMENT:13:$LEN_VALUE}
                    continue
                fi



                if [[ "$ARGUMENT" == "-bl="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-4))
                    BUILD_LABEL=${ARGUMENT:4:$LEN_VALUE}
                    continue
                fi

                if [[ "$ARGUMENT" == "--build-label="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-14))
                    BUILD_LABEL=${ARGUMENT:14:$LEN_VALUE}
                    continue
                fi



                if [[ "$ARGUMENT" == "-io="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-4))
                    INFORMATION_OUTPUT=$INVOCATION_PATH/${ARGUMENT:4:$LEN_VALUE}
                    continue
                fi

                if [[ "$ARGUMENT" == "--info-output="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-14))
                    INFORMATION_OUTPUT=$INVOCATION_PATH/${ARGUMENT:14:$LEN_VALUE}
                    continue
                fi



                if [[ "$ARGUMENT" == "-eo="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-4))
                    ERROR_OUTPUT=$INVOCATION_PATH/${ARGUMENT:4:$LEN_VALUE}
                    continue
                fi

                if [[ "$ARGUMENT" == "--error-output="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-15))
                    ERROR_OUTPUT=$INVOCATION_PATH/${ARGUMENT:15:$LEN_VALUE}
                    continue
                fi



                if [[ $ACCEPT == "ALL" ]];
                then
                    echo "error: unknown flag: '$ARGUMENT'" >>$ERROR_OUTPUT
                    exit 1
                fi
                ;;

            "MODULE-NAME")
                if [[ "$ARGUMENT" == "-"* ]];
                then
                    echo "error: missing module list after flag" >>$ERROR_OUTPUT
                    exit 1
                fi
                SPECIFIED_MODULES="$ARGUMENT"
                ACCEPT="ALL"
                ;;

            "TEST-TYPES")
                if [[ "$ARGUEMNT" == "-"* ]];
                then
                    echo "error: missing test type after flag" >>$ERROR_OUTPUT
                    exit 1
                fi
                SPECIFIED_TEST_TYPES="$ARGUMENT"
                ACCEPT="ALL"
                ;;

            "BUILD-LABEL")
                if [[ "$ARGUMENT" == "-"* ]];
                then
                    echo "error: missing build label after flag" >>$ERROR_OUTPUT
                    exit 1
                fi
                BUILD_LABEL="$ARGUMENT"
                ACCEPT="ALL"
                ;;

            "INFO-OUTPUT")
                if [[ "$ARGUMENT" == "-"* ]];
                then
                    echo "error: missing information output after flag" >>$ERROR_OUTPUT
                    exit 1
                fi
                INFORMATION_OUTPUT="$ARGUMENT"
                ACCEPT="ALL"
                ;;

            "ERROR-OUTPUT")
                if [[ "$ARGUMENT" == "-"* ]];
                then
                    echo "error: missing error output after flag" >>$ERROR_OUTPUT
                    exit 1
                fi
                ERROR_OUTPUT="$ARGUMENT"
                ACCEPT="ALL"
                ;;

            *)
                echo "error: invalid state in 'gather_arguments'" >>$ERROR_OUTPUT
                ACCEPT="ALL"
        esac
    done
}

make_instance_log_folder() {
    echo "info: log creation not supported" >>$INFORMATION_OUTPUT
}

make_build() {
    # Create a folder for this build

    local BUILD_PATH="$I686_PATH/.tests/builds/$START_TIME"
    if [[ -d $BUILD_PATH ]];
    then
        echo "info: deleting old build already named '$BUILD_LABEL'." >>$INFORMATION_OUTPUT
        rm -r $BUILD_PATH
    fi

    mkdir -p $BUILD_PATH/suites

    # Write the build config log

    local BUILD_CONFIG="$BUILD_PATH/build_config.ini"
    echo "[Build]" >>$BUILD_CONFIG
    echo "Label = \"$BUILD_LABEL\"" >>$BUILD_CONFIG
    echo "Modules = \"$MODULE_LIST\"" >>$BUILD_CONFIG
    
    echo "$BUILD_PATH"
}

process_config_path() {

    local STRING=${1/"{test}"/"$2"}
    STRING=${STRING/"{bootsector}"/$BOOTSECTOR_PATH}
    STRING=${STRING/"{code-partition}"/$CODE_PARTITION_PATH}
    STRING=${STRING/"{bootfs}"/$BOOT_FS_PATH}

    echo $STRING
}

read_config_path() {
    # Argument 1: Test Config
    # Argument 2: Test Source Root
    # Argument 3: Configuration Key

    local RAW_STRING=$($INI --get $3 $1)
    process_config_path $RAW_STRING $2
}

process_include_path_list() {
    # Argument 1: Comma-separated list of include paths before the processing

    IFS="," read -ra INCLUDE_PATHS <<< "$1"
    for INCLUDE_PATH in ${INCLUDE_PATHS[@]};
    do
        process_config_path " -i $INCLUDE_PATH" "$2"
    done
}

run_builtin_nasm_builder() {
    # Argument 1: Test-suite root folder
    
    local CONFIG_PATH="$1/sources/test.ini"
    local RAW_INCLUDE_PATHS=$($INI -g Building:Include-Paths $CONFIG_PATH)

    local INCLUDE_PATH_LIST=$(process_include_path_list $RAW_INCLUDE_PATHS "$1/sources")
    local SOURCE_PATH=$(read_config_path $CONFIG_PATH "$1/sources" Building:Source)

    local TEST_ENVIRONMENT=$($INI -g General:Environment $CONFIG_PATH)

    if [[ $TEST_ENVIRONMENT == "bootable" ]];
    then
        nasm -fbin -o "$1/objects/object.bin" $SOURCE_PATH $INCLUDE_PATH_LIST
    fi

    if [[ $TEST_ENVIRONMENT == "host" ]];
    then
        OBJECT_FILE="$1/objects/object.o"
        EXECUTABLE_FILE="$1/objects/object.elf"
        nasm -felf32 -o $OBJECT_FILE $SOURCE_PATH $INCLUDE_PATH_LIST
        ld -m elf_i386 -o $EXECUTABLE_FILE $OBJECT_FILE
    fi
}

run_user_script_builder() {
    local TEST_NAME=$(read_config_path "$1/sources/test.ini" "$1/sources" General:Name)
    local BUILD_SCRIPT_PATH=$(read_config_path "$1/sources/test.ini" "$1/sources" Scripts:Build)
    if [[ ! -f $USER_SCRIPT_PATH ]];
    then
        echo "error: no build script for user-built test '$TEST_NAME'." >>$ERROR_OUTPUT
        return
    fi
    $BUILD_SCRIPT_PATH $I686_PATH
}

build_single_unit_test_suite() {
    # Argument 1: Unit Test Source Root
    # Argument 2: Test Build's Root Path

    # Gather test's name for creating the test suite - folders

    local TEST_NAME=$($INI -g General:Name "$1/test.ini")

    echo "info: building unit test '$TEST_NAME'" >>$INFORMATION_OUTPUT

    # Create test suite - folders

    local SUITE_ROOT_FOLDER="$2/suites/$TEST_NAME"
    mkdir -p $SUITE_ROOT_FOLDER/sources $SUITE_ROOT_FOLDER/objects

    cp -R "$1"/* $SUITE_ROOT_FOLDER/sources
    cd $SUITE_ROOT_FOLDER

    # Gather config values

    local TEST_CONFIG="$SUITE_ROOT_FOLDER/sources/test.ini"

    local TEST_VERSION=$($INI -g General:Version $TEST_CONFIG)
    local TEST_ENVIRONMENT=$($INI -g General:Environment $TEST_CONFIG)
    local TEST_BUILDER=$($INI -g Building:Builder $TEST_CONFIG)

    cd sources

    local PRE_BUILD_SCRIPT=$(read_config_path $TEST_CONFIG $SUITE_ROOT_FOLDER/sources "Scripts:Pre-Build")
    if [[ -f $PRE_BUILD_SCRIPT ]];
    then
        $PRE_BUILD_SCRIPT $I686_PATH
    fi

    case $TEST_BUILDER in
        "builtin/nasm")
            run_builtin_nasm_builder $SUITE_ROOT_FOLDER
            ;;
        "user-script")
            run_user_script_builder $SUITE_ROOT_FOLDER
            ;;
        *)
            echo "error: unknown test-builder for unit test '$TEST_NAME'." >>$ERROR_OUTPUT
            ;;
    esac

    local PACKAGING_SCRIPT=$(read_config_path $TEST_CONFIG $SUITE_ROOT_FOLDER "Scripts:Package")
    if [[ -f $PACKAGING_SCRIPT ]];
    then
        $PACKAGING_SCRIPT "$I686_PATH" "$2/suites/$TEST_NAME"
    fi

    cd ..
}

build_all_module_unit_tests( ) {
    # Argument 1: Module Name
    # Argument 2: Test Build's Root Path

    local MODULE_PATH="$I686_PATH/modules/$1"
    local UNIT_TEST_NAMES=$(ls -A $MODULE_PATH/tests/unit)
    for UNIT_TEST_NAME in $UNIT_TEST_NAMES
    do
        local UNIT_TEST_PATH="$MODULE_PATH/tests/unit/$UNIT_TEST_NAME"

        if [[ ! -d "$UNIT_TEST_PATH" ]];
        then
            continue
        fi

        if [[ "$UNIT_TEST_PATH" == ".private" ]];
        then
            continue
        fi

        if [[ ! -f "$UNIT_TEST_PATH/test.ini" ]];
        then
            echo "error: configuration file 'test.ini' not found in unit test '$UNIT_TEST_NAME'" >>$ERROR_OUTPUT
            continue
        fi

        build_single_unit_test_suite "$UNIT_TEST_PATH" "$2"
    done
}

build_single_module_peek() {
    # Argument 1: Peek Source Root
    # Argument 2: Test Build's Root Path

    # Create test suite - folders

    local SUITE_ROOT_FOLDER="$2/suites/$TEST_NAME"
    mkdir -p $SUITE_ROOT_FOLDER/sources $SUITE_ROOT_FOLDER/objects

    cp -R "$1"/* $SUITE_ROOT_FOLDER/sources
    cd $SUITE_ROOT_FOLDER

    # Gather config values

    local TEST_CONFIG="$SUITE_ROOT_FOLDER/sources/test.ini"

    local TEST_NAME=$($INI -g General:Name "$1/test.ini")
    local TEST_VERSION=$($INI -g General:Version $TEST_CONFIG)
    local TEST_BUILDER=$($INI -g Building:Builder $TEST_CONFIG)

    echo "info: building peek '$TEST_NAME'" >>$INFORMATION_OUTPUT

    # Gather config values

    cd sources

    local PRE_BUILD_SCRIPT=$(read_config_path $TEST_CONFIG $SUITE_ROOT_FOLDER/sources "Scripts:Pre-Build")
    if [[ -f $PRE_BUILD_SCRIPT ]];
    then
        $PRE_BUILD_SCRIPT $I686_PATH
    fi

    case $TEST_BUILDER in
        "builtin/nasm")
            run_builtin_nasm_builder $SUITE_ROOT_FOLDER
            ;;
        "user-script")
            run_user_script_builder $SUITE_ROOT_FOLDER
            ;;
        *)
            echo "error: unknown test-builder for peek '$TEST_NAME'" >>$ERROR_OUTPUT
            ;;
    esac

    local PACKAGING_SCRIPT=$(read_config_path $TEST_CONFIG $SUITE_ROOT_FOLDER "Scripts:Package")
    if [[ -f $PACKAGING_SCRIPT ]];
    then
        $PACKAGING_SCRIPT "$I686_PATH" "$2/suites/$TEST_NAME"
    fi

    cd ..
}

build_all_module_peeks() {
    # Argument 1: Module Name
    # Argument 2: Test Build's Root Path

    local MODULE_PATH="$I686_PATH/modules/$1"
    local PEEK_NAMES=$(ls -A $MODULE_PATH/tests/peeks)
    for PEEK_NAME in $PEEK_NAMES;
    do
        local PEEK_SOURCE_PATH="$MODULE_PATH/tests/peeks/$PEEK_NAME"

        if [[ ! -d "$PEEK_SOURCE_PATH" ]];
        then
            continue
        fi

        if [[ "$PEEK_NAME" == ".private" ]];
        then
            continue
        fi

        if [[ ! -f "$PEEK_SOURCE_PATH/test.ini" ]];
        then
            echo "error: configuration file 'test.ini' not found in peek '$PEEK_NAME'" >>$ERROR_OUTPUT
            continue
        fi
        # @todo: parse peek's 'test.ini' and build according to it
        build_single_module_peek "$PEEK_SOURCE_PATH" "$2"
    done
}

build_all_tests_of_single_module() {
    # Argument 1: Module Name

    local MODULE_PATH="$I686_PATH/modules/$1"

    if [[ ! -d "$MODULE_PATH/tests/" ]];
    then
        echo "info: skipping module without tests named '$1'" >>$INFORMATION_OUTPUT
        return
    fi
    echo "info: building tests of module '$1'" >>$INFORMATION_OUTPUT

    local BUILD_PATH=$(make_build)



    local UNIT_TESTS_BUILD=0
    local PEEKS_BUILD=0

    IFS="," read -ra SPLIT_TEST_TYPE_LIST <<< "$SPECIFIED_TEST_TYPES"
    for TEST_TYPE in "${SPLIT_TEST_TYPE_LIST[@]}"
    do
        case "$TEST_TYPE" in
            "unit")
                if [[ $UNIT_TESTS_BUILD == 0 ]];
                then
                    build_all_module_unit_tests "$1" "$BUILD_PATH"
                fi
                UNIT_TESTS_BUILD=1
                ;;

            "peek")
                if [[ $PEEKS_BUILD == 0 ]];
                then
                    build_all_module_peeks "$1" "$BUILD_PATH"
                fi
                PEEKS_BUILD=1
                ;;
        esac
    done
}

build_all_tests_of_all_modules() {
    # Argument 1: Comma-separated list of modules to build the tests of

    IFS=',' read -ra SPLIT_MODULE_LIST <<< "$1"
    for MODULE_NAME in "${SPLIT_MODULE_LIST[@]}"
    do
        build_all_tests_of_single_module $MODULE_NAME
    done
}

gather_arguments "$@"
build_all_tests_of_all_modules "$SPECIFIED_MODULES"
