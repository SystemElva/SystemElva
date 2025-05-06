#!/bin/bash

cd $(dirname $0)/../..
I686_PATH=$(pwd)

# Script Dependencies

INI="$I686_PATH/src-sh/ini.sh"

# Run-Time Constants (set once, used until the end)

START_TIME=$(date "+%Y-%m-%d.%H-%M-%S")

BOOTSECTOR_PATH=$I686_PATH/modules/bootsector
CODE_PARTITION_PATH=$I686_PATH/modules/code-partition
BOOTFS_PATH=$I686_PATH/modules/bootfs

# Arguments (to be set in 'gather_arguments')

SPECIFIED_MODULES="code-partition"
BUILD_LABEL=$START_TIME

gather_arguments() {
    ARGUMENTS=$@

    ACCEPT="ALL"
    for ARGUMENT in $ARGUMENTS
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

                if [[ $ACCEPT == "ALL" ]];
                then
                    echo "Unknown argument initializer: $ARGUMENT"
                    exit 2
                fi
                ;;
            "MODULE-NAME")
                if [[ "$ARGUMENT" == "-"* ]];
                then
                    echo "Missing module list after argument initializer"
                    exit 1
                fi
                SPECIFIED_MODULES="$ARGUMENT"
                ACCEPT="ALL"
                ;;
            "BUILD-LABEL")
                if [[ "$ARGUMENT" == "-"* ]];
                then
                    echo "Missing build label after argument initializer"
                    exit 1
                fi
                BUILD_LABEL="$ARGUMENT"
                ACCEPT="ALL"
                ;;
            *)
                echo "Internal Error: Invalid state in 'gather_arguments'."
                ACCEPT="ALL"
        esac
    done
}

make_instance_log_folder() {
    echo "not supported" >&2
}

make_build() {
    # Create a folder for this build

    BUILD_PATH="$I686_PATH/.tests/builds/$START_TIME"
    if [[ -d $BUILD_PATH ]];
    then
        echo "INFO: Deleting old build named '$BUILD_LABEL'." >&0
        rm -r $BUILD_PATH
    fi

    mkdir -p $BUILD_PATH/suites

    # Write the build config log

    echo $BUILD_PATH
    BUILD_CONFIG="$BUILD_PATH/build_config.ini"
    echo "[Build]" >> $BUILD_CONFIG
    echo "Label = \"$BUILD_LABEL\"" >> $BUILD_CONFIG
    echo "Modules = \"$MODULE_LIST\"" >> $BUILD_CONFIG
    
    echo "$BUILD_PATH"
}

process_config_path() {
    RAW_STRING=$1
    TEST_PATH=$2

    STRING=${RAW_STRING/"{test}"/$TEST_PATH}
    STRING=${STRING/"{bootsector}"/$BOOTSECTOR_PATH}
    STRING=${STRING/"{code-partition}"/$CODE_PARTITION_PATH}
    STRING=${STRING/"{bootfs}"/$BOOT_FS_PATH}

    echo $STRING
}

read_config_path() {
    TEST_CONFIG=$1
    TEST_SOURE_ROOT=$2
    CONFIG_KEY=$3

    RAW_STRING=$($INI --get $CONFIG_KEY $TEST_CONFIG)
    process_config_path $RAW_STRING $TEST_SOURE_ROOT
}

process_include_path_list() {
    COMMA_SEPARATED_LIST=$1

    IFS="," read -ra INCLUDE_PATHS <<< "$COMMA_SEPARATED_LIST"
    for INCLUDE_PATH in ${INCLUDE_PATHS[@]};
    do
        process_config_path " -i $INCLUDE_PATH"
    done
}

run_builtin_nasm_builder() {
    SUITE_BUILD_FOLDER="$1"
    
    TEST_CONFIG=$SUITE_BUILD_FOLDER/test.ini
    RAW_INCLUDE_PATHS=$($INI -g Building:Include-Paths $TEST_CONFIG)

    INCLUDE_PATH_LIST=$(process_include_path_list $RAW_INCLUDE_PATHS)
    SOURCE_PATH=$(read_config_path $TEST_CONFIG $SUITE_BUILD_FOLDER Building:Source)

    nasm -fbin -o $SUITE_BUILD_FOLDER/../objects/object.bin $SOURCE_PATH $INCLUDE_PATH_LIST
}

run_user_script_builder() {
    SUITE_BUILD_FOLDER="$1"

    USER_SCRIPT_PATH=$(read_config_path $TEST_CONFIG $SUITE_BUILD_FOLDER Scripts:Build)
    $USER_SCRIPT_PATH $I686_PATH
}

build_single_unit_test_suite() {
    SUITE_SOURCE_FOLDER="$1"
    BUILD_PATH="$2"

    # Gather test's name for creating the test suite - folders

    TEST_NAME=$($INI -g General:Name $SUITE_SOURCE_FOLDER/test.ini)

    # Create test suite - folders

    SUITE_BUILD_FOLDER="$BUILD_PATH/suites/$UNIT_TEST_NAME"
    mkdir $SUITE_BUILD_FOLDER
    mkdir $SUITE_BUILD_FOLDER/sources $SUITE_BUILD_FOLDER/objects

    cp -R $SUITE_SOURCE_FOLDER/* $SUITE_BUILD_FOLDER/sources
    cd $SUITE_BUILD_FOLDER

    # Gather config values

    TEST_CONFIG=$SUITE_BUILD_FOLDER/sources/test.ini
    TEST_VERSION=$($INI -g General:Version $TEST_CONFIG)
    TEST_ENVIRONMENT=$($INI -g General:Environment $TEST_CONFIG)
    TEST_BUILDER=$($INI -g Building:Builder $TEST_CONFIG)

    cd sources

    PRE_BUILD_SCRIPT=$(read_config_path $TEST_CONFIG $SUITE_BUILD_FOLDER/sources "Scripts:Pre-Build")
    $PRE_BUILD_SCRIPT $I686_PATH

    case $TEST_BUILDER in
        "builtin/nasm")
            run_builtin_nasm_builder $SUITE_BUILD_FOLDER/sources
            ;;
        "user-script")
        run_user_script_builder $SUITE_BUILD_FOLDER/sources
            ;;
    esac

    PACKAGING_SCRIPT=$(read_config_path $TEST_CONFIG $SUITE_BUILD_FOLDER "Scripts:Package")
    $PACKAGING_SCRIPT $I686_PATH "$BUILD_PATH/suites/$UNIT_TEST_NAME"

    cd ..
}

build_all_module_unit_tests( ) {
    MODULE_NAME="$1"
    BUILD_PATH="$2"

    MODULE_PATH="$I686_PATH/modules/$MODULE_NAME"

    UNIT_TEST_NAMES=$(ls $MODULE_PATH/tests/unit)
    for UNIT_TEST_NAME in $UNIT_TEST_NAMES
    do
        UNIT_TEST_PATH=$MODULE_PATH/tests/unit/$UNIT_TEST_NAME

        # Skip hidden unit tests
        if [[ $UNIT_TEST_NAME == .* ]];
        then
            continue
        fi
        if [[ ! -f "$UNIT_TEST_PATH/test.ini" ]];
        then
            echo "Failed finding file 'test.ini' for unit test '$UNIT_TEST_NAME'!"
            continue
        fi

        build_single_unit_test_suite $UNIT_TEST_PATH $BUILD_PATH
    done
}

build_all_module_peeks() {
    MODULE_NAME="$1"
    BUILD_PATH="$2"

    MODULE_PATH="$I686_PATH/modules/$MODULE_NAME"

}

build_all_tests_of_single_module() {
    MODULE_NAME="$1"
    MODULE_PATH="$I686_PATH/modules/$MODULE_NAME"

    if [[ ! -d "$MODULE_PATH/tests/" ]];
    then
        echo "> No tests found in module '$MODULE_NAME'. Skipping..."
        return
    fi
    echo "> Building tests of module '$MODULE_NAME'"

    BUILD_PATH=$(make_build)

    if [[ -d "$MODULE_PATH/tests/unit" ]];
    then
        build_all_module_unit_tests $MODULE_NAME $BUILD_PATH
    fi

    if [[ -d "$MODULE_PATH/tests/peek" ]];
    then
        build_all_module_peeks $MODULE_NAME $BUILD_PATH
    fi
}

build_tests_of_modules() {
    MODULE_LIST=$1

    IFS=',' read -ra SPLIT_MODULE_LIST <<< "$MODULE_LIST"
    for MODULE_NAME in "${SPLIT_MODULE_LIST[@]}"
    do
        build_all_tests_of_single_module $MODULE_NAME
    done
}

gather_arguments "$@"
build_tests_of_modules $SPECIFIED_MODULES
