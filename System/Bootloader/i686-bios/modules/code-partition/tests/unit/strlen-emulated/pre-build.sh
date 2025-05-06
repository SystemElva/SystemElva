#!/bin/bash

cd $(dirname $0)
TEST_FOLDER=$(pwd)

if [[ -f "$TEST_FOLDER/generated_test_cases.asm" ]];
then
    rm "$TEST_FOLDER/generated_test_cases.asm"
fi

TEST_CASE_PATH=$TEST_FOLDER/assets/test_cases.txt

while IFS= read -r LINE
do
    if [[ "$LINE" == *\"* ]];
    then
        echo -e "\e[31mERROR in 'pre-build.sh' of test: 'strlen'!\e[0m"
        echo -e "\e[31massets/test_cases.txt contains disallowed character: '\"'.\e[0m"
        exit 1
    fi

    if [[ "$LINE" == *\\* ]];
    then
        echo -e "\e[31mERROR in 'pre-build.sh' of test: 'strlen'!\e[0m"
        echo -e "\e[31mtest_cases.txt contains disallowed character: '\\'.\e[0m"
        exit 1
    fi
done < "$TEST_CASE_PATH"



echo "; Automatically generated file. Edit 'test_cases.txt' instead!" \
    >> "$TEST_FOLDER/generated_test_cases.asm"
echo "" >> "$TEST_FOLDER/generated_test_cases.asm"

LABEL_ID="1"
echo "text_pointers:" >> "$TEST_FOLDER/generated_test_cases.asm"
while IFS= read -r LINE
do
    echo "    dd ${#LINE}, text.string_$LABEL_ID" >> "$TEST_FOLDER/generated_test_cases.asm"
    ((LABEL_ID=$LABEL_ID+1))
done < "$TEST_CASE_PATH"
echo "    dd 0, 0" >> "$TEST_FOLDER/generated_test_cases.asm"
echo "" >> "$TEST_FOLDER/generated_test_cases.asm"



LABEL_ID="1"
echo "text:" >> "$TEST_FOLDER/generated_test_cases.asm"
while IFS= read -r LINE
do
    echo ".string_$LABEL_ID:" >> "$TEST_FOLDER/generated_test_cases.asm"
    echo "    db \"$LINE\", 0x00" >> "$TEST_FOLDER/generated_test_cases.asm"
    ((LABEL_ID=$LABEL_ID+1))
done < "$TEST_CASE_PATH"
echo "" >> "$TEST_FOLDER/generated_test_cases.asm"

