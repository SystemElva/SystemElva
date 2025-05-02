#!/bin/bash

cd $(dirname $0)
TEST_FOLDER=$(pwd)

if [[ -f "$TEST_FOLDER/$OUTPUT_FILE" ]];
then
    rm "$TEST_FOLDER/$OUTPUT_FILE"
fi

generate_asset_file() {
    ASSET_FILE="$1"
    OUTPUT_FILE="$2"
    LABEL_PREFIX="$3"

    if [[ -f "$TEST_FOLDER/$OUTPUT_FILE" ]];
    then
        rm "$TEST_FOLDER/$OUTPUT_FILE"
    fi

    while IFS= read -r LINE
    do
        if [[ "$LINE" == *\"* ]];
        then
            echo -e "\e[31mERROR in 'pre-build.sh' of test: 'fat12-is-long-file-name'!\e[0m"
            echo -e "\e[31m$ASSET_FILE contains disallowed character: '\"'.\e[0m"
            exit 1
        fi

        if [[ "$LINE" == *\\* ]];
        then
            echo -e "\e[31mERROR in 'pre-build.sh' of test: 'fat12-is-long-file-name'!\e[0m"
            echo -e "\e[31m$ASSET_FILE contains disallowed character: '\\'.\e[0m"
            exit 1
        fi
    done < "$TEST_FOLDER/$ASSET_FILE"



    echo "; Automatically generated file. Edit '$ASSET_FILE' instead!" \
        >> "$TEST_FOLDER/$OUTPUT_FILE"
    echo "" >> "$TEST_FOLDER/$OUTPUT_FILE"

    LABEL_ID="1"
    echo "${LABEL_PREFIX}_file_name_pointers:" >> "$TEST_FOLDER/$OUTPUT_FILE"
    while IFS= read -r LINE
    do
        if [[ ${LINE:0:1} == "#" ]];
        then
            continue
        fi

        echo "    dd ${LABEL_PREFIX}_file_names.string_$LABEL_ID" >> "$TEST_FOLDER/$OUTPUT_FILE"
        ((LABEL_ID=$LABEL_ID+1))
    done < "$TEST_FOLDER/$ASSET_FILE"
    echo "    dd 0" >> "$TEST_FOLDER/$OUTPUT_FILE"
    echo "" >> "$TEST_FOLDER/$OUTPUT_FILE"



    LABEL_ID="1"
    echo "${LABEL_PREFIX}_file_names:" >> "$TEST_FOLDER/$OUTPUT_FILE"
    while IFS= read -r LINE
    do
        if [[ ${LINE:0:1} == "#" ]];
        then
            continue
        fi

        echo ".string_$LABEL_ID:" >> "$TEST_FOLDER/$OUTPUT_FILE"
        echo "    db \"$LINE\", 0x00" >> "$TEST_FOLDER/$OUTPUT_FILE"
        ((LABEL_ID=$LABEL_ID+1))
    done < "$TEST_FOLDER/$ASSET_FILE"
    echo "" >> "$TEST_FOLDER/$OUTPUT_FILE"
}

generate_asset_file "short_file_names.txt" "generated_short_file_names.asm" "short"
generate_asset_file "long_file_names.txt" "generated_long_file_names.asm" "long"

