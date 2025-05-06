#!/bin/bash

cd $(dirname $0)/../..
I686_PATH=$(pwd)

# Script Dependencies

INI="$I686_PATH/src-sh/ini.sh"

START_TIME=$(date "+%Y-%m-%d.%H-%M-%S")
TEST_BUILD_LIST=$(ls $I686_PATH/.tests/builds | sort --reverse)

BUILD_INDEX="0"
BUILD_LABEL=0
ALL_TEST_SUITES=1
INPUT_TEST_SUITES=""

validate_build_index() {
    GIVEN_NUMBER=$1

    ((NUM_BUILDS=$(echo $TEST_BUILD_LIST | wc -l)+2))

    if [[ $TEST_BUILD_LIST == "" ]];
    then
        echo "FAIL(run-script): No test builds have been created yet!"
        exit 1
    fi
    if [[ $GIVEN_NUMBER -lt 0 ]];
    then
        echo "FAIL(run-script): Build Index must be larger than zero. Given: $GIVEN_NUMBER"
        exit 1
    fi
    if [[ $GIVEN_NUMBER -gt $NUM_BUILDS ]];
    then
        echo "FAIL(run-script): Build Index is too large. Given: $GIVEN_NUMBER. Oldest: $NUM_BUILDS"
        exit 1
    fi
    BUILD_INDEX=$GIVEN_NUMBER
}

gather_arguments() {
    ARGUMENTS=$@

    ACCEPT="ALL"
    for ARGUMENT in $ARGUMENTS
    do
        case $ACCEPT in
            "ALL")
                if [[ "$ARGUMENT" == "-i" || "$ARGUMENT" == "--index" ]];
                then
                    ACCEPT="INDEX"

                    validate_build_index $BUILD_INDEX
                    continue
                fi
                if [[ "$ARGUMENT" == "-bl" || "$ARGUMENT" == "--build-label" ]];
                then
                    ACCEPT="BUILD-LABEL"
                    continue
                fi
                if [[ "$ARGUMENT" == "-s" || "$ARGUMENT" == "--suites" ]];
                then
                    ACCEPT="TEST-SUITES"
                    continue
                fi

                if [[ "$ARGUMENT" == "-i="* ]];
                then
                    BUILD_LABEL=0

                    ((LEN_VALUE=${#ARGUMENT}-3))
                    validate_build_index ${ARGUMENT:3:$LEN_VALUE}
                    continue
                fi
                if [[ "$ARGUMENT" == "--index="* ]];
                then
                    BUILD_LABEL=0

                    ((LEN_VALUE=${#ARGUMENT}-8))
                    validate_build_index ${ARGUMENT:8:$LEN_VALUE}
                    continue
                fi

                if [[ "$ARGUMENT" == "-bl="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-4))
                    BUILD_LABEL=${ARGUMENT:4:$LEN_VALUE}
                    BUILD_INDEX=0
                    continue
                fi
                if [[ "$ARGUMENT" == "--build-label="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-14))
                    BUILD_LABEL=${ARGUMENT:14:$LEN_VALUE}
                    BUILD_INDEX=0
                    continue
                fi

                if [[ "$ARGUMENT" == "-s="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-3))
                    INPUT_TEST_SUITES=${ARGUMENT:3:$LEN_VALUE}
                    continue
                fi
                if [[ "$ARGUMENT" == "--suites="* ]];
                then
                    ((LEN_VALUE=${#ARGUMENT}-9))
                    INPUT_TEST_SUITES=${ARGUMENT:9:$LEN_VALUE}
                    continue
                fi
                ;;
            "INDEX")
                BUILD_INDEX=$ARGUMENT
                BUILD_LABEL=0

                validate_build_index $BUILD_INDEX
                ACCEPT="ALL"
                ;;
            "BUILD-LABEL")
                BUILD_LABEL=$ARGUMENT
                BUILD_INDEX=0
                ACCEPT="ALL"
                ;;
            "TEST-SUITES")
                ALL_TEST_SUITES=0
                INPUT_TEST_SUITES=$ARGUMENT
                ACCEPT="ALL"
                ;;
        esac
    done
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

search_labelled_test_build() {
    if [[ $TEST_BUILD_LIST == "" ]];
    then
        echo "FAIL(run-script): No test builds have been created yet!"
        exit 1
    fi

    INDEX_COUNTER=1
    for TEST_BUILD in $TEST_BUILD_LIST
    do
        TEST_BUILD_CONFIG_PATH=$I686_PATH/.tests/builds/$TEST_BUILD/build_config.ini

        CURRENT_LABEL=$($INI -g Build:Label $TEST_BUILD_CONFIG_PATH)
        if [[ $CURRENT_LABEL == $BUILD_LABEL ]];
        then
            BUILD_INDEX=-$INDEX_COUNTER
            return
        fi
        ((INDEX_COUNTER++))
    done

    echo "FAIL(run-script): Couldn't find test build with label '$BUILD_LABEL'!"
    exit 1
}

write_unit_test_suite_log_separator() {
    CONFIG_PATH=$1

    printf "======== Running test suite: " >> $LOG_PATH
    printf $($INI -g General:Name $CONFIG_PATH) >> $LOG_PATH
    echo " ========" >> $LOG_PATH

    echo "" >> $LOG_PATH
    printf "## test.ini:\n" >> $LOG_PATH
    cat $CONFIG_PATH | while read INI_LINE 
    do
        echo "# $INI_LINE" >> $LOG_PATH
    done

    echo -e "\n-------- Starting specific output --------" >> $LOG_PATH
}

run_single_test_unit_suite() {
    TEST_SUITE_NAME=$1

    TEST_SUITE_PATH=$TEST_BUILD_FOLDER/suites/$TEST_SUITE_NAME
    EXECUTE_SCRIPT=$(read_config_path \
        $TEST_SUITE_PATH/sources/test.ini \
        $TEST_SUITE_PATH/sources \
        Scripts:Execute)

    cd $TEST_SUITE_PATH
    if [[ -f $EXECUTE_SCRIPT ]];
    then
        write_unit_test_suite_log_separator $TEST_SUITE_PATH/sources/test.ini
        $EXECUTE_SCRIPT $LOG_PATH
    fi
}

run_all_unit_test_suites() {
    TEST_BUILD_FOLDER=$1

    if [[ $ALL_TEST_SUITES == 0 ]];
    then
        IFS="," read -ra TEST_SUITES <<< "$INPUT_TEST_SUITES"
    else
        TEST_SUITES=$(ls $TEST_BUILD_FOLDER/suites)
    fi

    for TEST_SUITE in ${TEST_SUITES[@]};
    do
        if [[ ! -d $TEST_BUILD_FOLDER/$TEST_SUITE_NAME ]];
        then
            echo "FAIL(run-script): Unknown test suite: $TEST_SUITE"
            continue
        fi
        run_single_test_unit_suite $TEST_SUITE
    done
}




gather_arguments "$@"

if [[ $BUILD_LABEL != 0 ]];
then
    search_labelled_test_build $BUILD_LABEL
fi

((FIELD_INDEX=$BUILD_INDEX+1))

BUILD_FOLDER=$(echo $TEST_BUILD_LIST | cut -d" " -f$FIELD_INDEX)
BUILD_FOLDER="$I686_PATH/.tests/builds/$BUILD_FOLDER"

mkdir -p $I686_PATH/.tests/logs
LOG_PATH=$I686_PATH/.tests/logs/$START_TIME.log

echo -e "Test Build Instance - Start Time: $START_TIME\n" >> $LOG_PATH

run_all_unit_test_suites $BUILD_FOLDER
