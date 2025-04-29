#!/bin/sh

INI_FILE="/dev/stdin"
OUTPUT="/dev/stdout"
ACTION="UNKNOWN"

parse_query() {
    QUERY_ARGUMENT=$1

    LEN_QUERY=${#QUERY_ARGUMENT}
    CHAR_INDEX=0
    while [[ $CHAR_INDEX -le $LEN_QUERY ]];
    do
        if [[ ${QUERY_ARGUMENT:$CHAR_INDEX:1} == ':' ]];
        then
            SECTION_NAME=$(echo $QUERY_ARGUMENT | cut -c -$CHAR_INDEX)
            ((CHAR_INDEX+=2))
            KEY_NAME=$(echo $QUERY_ARGUMENT | cut -c $CHAR_INDEX-)
            return
        fi
        ((CHAR_INDEX+=1))
    done

}

parse_arguments() {
    ARGUMENT_INDEX=0
    ACCEPT="ALL"
    if [[ $ACTION == "GET-VALUE" ]];
    then
        ACCEPT="QUERY"
    fi

    if [[ $ACTION == "LIST-FIELDS" ]];
    then
        ACCEPT="SECTION-NAME"
    fi

    for ARGUMENT in "$@"
    do
        ((ARGUMENT_INDEX++))
        # Jump over the first two arguments as they're:
        #  1) the script's name
        #  2) the name of the action
        if [[ $ARGUMENT_INDEX < 2 ]];
        then
            continue
        fi
        case $ACCEPT in
            "ALL")
                case $ARGUMENT in
                    "-o" | "--output")
                        ACCEPT="OUTPUT"
                        ;;
                    "-q" | "--query")
                        ACCEPT="QUERY"
                        ;;
                esac
                # If the argument doesn't start with a minus,
                #  treat it as the input file's name.
                if [[ ${ARGUMENT:0:1} != "-" ]];
                then
                    INI_FILE=$ARGUMENT
                fi
                ;;
            "OUTPUT")
                if [[ ${ARGUMENT:0:1} == "-" ]];
                then
                    echo "Output file name cannot begin with '-'."
                    SUCCESS=0
                fi
                OUTPUT=$ARGUMENT
                ACCEPT="ALL"
                ;;
            "QUERY")
                parse_query $ARGUMENT
                ACCEPT="ALL"
                ;;
            "SECTION-NAME")
                SECTION_NAME=$ARGUMENT
                ACCEPT=ALL
                ;;
        esac
    done

    case $ACCEPT in
    "INI-FILE")
        echo "Missing input path at end of argument stream."
        exit -1
        ;;
    
    "OUTPUT")
        echo "Missing output path at end of argument stream."
        exit -2
        ;;
    esac
}

list_sections() {
    parse_arguments "$@"

    while read LINE
    do
        if [[ ${LINE:0:1} == "[" ]];
        then
            ((LAST_USED_OFFSET=${#LINE}-2))
            echo "${LINE:1:LAST_USED_OFFSET}" >> $OUTPUT
        fi
    done <$INI_FILE
}

list_fields() {
    parse_arguments "$@"

    SEARCHING=1
    while read LINE
    do
        # If the line is empty, it makes no sense to waste time on it.
        if [[ $LINE == "" ]];
        then
            continue
        fi

        # Check if the first character of this line is a hashtag
        # And skip this line if it is, because that means it's a comment.
        if [[ ${LINE:0:1} == "#" ]];
        then
            continue
        fi
        if [[ $SEARCHING == 1 ]];
        then
            if [[ ${LINE:0:1} == "[" ]];
            then
                ((LAST_USED_OFFSET=${#LINE}-2))
                THIS_SECTION_NAME=${LINE:1:$LAST_USED_OFFSET}
                if [[ $THIS_SECTION_NAME == $SECTION_NAME ]];
                then
                    SEARCHING=0
                fi
                continue
            fi
        fi
        if [[ $SEARCHING == 0 ]];
        then
            if [[ ${LINE:0:1} == "[" ]];
            then
                return
            fi
            echo $LINE | cut -d= -f1 - >> $OUTPUT
        fi
    done <$INI_FILE
}

get_value() {
    parse_arguments "$@"

    SEARCHING=1
    while read LINE
    do
        # If the line is empty, it makes no sense to waste time on it.
        if [[ $LINE == "" ]];
        then
            continue
        fi

        # Check if the first character of this line is a hashtag
        # And skip this line if it is, because that means it's a comment.
        if [[ ${LINE:0:1} == "#" ]];
        then
            continue
        fi
        if [[ $SEARCHING == 1 ]];
        then
            if [[ ${LINE:0:1} == "[" ]];
            then
                ((LEN_LINE=${#LINE}-2))
                THIS_SECTION_NAME=${LINE:1:$LEN_LINE}
                if [[ $THIS_SECTION_NAME == $SECTION_NAME ]];
                then
                    SEARCHING=0
                fi
                continue
            fi
        fi
        if [[ $SEARCHING == 0 ]];
        then
            if [[ ${LINE:0:1} == "[" ]];
            then
                return
            fi
            CURRENT_KEY_NAME=$(echo $LINE | cut -d= -f1 -)

            # Cut away the possible spaces between
            # the key and the equals sign.
            CURRENT_KEY_NAME=$(echo $CURRENT_KEY_NAME | cut -d' ' -f1- -)

            if [[ $CURRENT_KEY_NAME == $KEY_NAME ]];
            then
                RAW_FIELD=$(echo $LINE | cut -d' ' -f3- -)

                # Remove the quotation marks in front of and after the field
                FIRST_CHARACTER=${RAW_FIELD:0:1}
                LAST_CHARACTER=${RAW_FIELD:((${#RAW_FIELD}-1)):1}
                if [[ $FIRST_CHARACTER == "\"" ]];
                then
                    if [[ $LAST_CHARACTER == "\"" ]];
                    then
                        ((LAST_WANTED_CHAR=${#RAW_FIELD}-1))
                        RAW_FIELD=$(echo $RAW_FIELD | cut -c 2-$LAST_WANTED_CHAR)
                    fi
                fi
                echo $RAW_FIELD >> $OUTPUT
            fi
        fi
    done <$INI_FILE
}

case $1 in
    "-l" | "--list-sections")
        ACTION="LIST-SECTIONS"
        list_sections "$@"
        ;;
    "-f" | "--list-fields")
        ACTION="LIST-FIELDS"
        list_fields "$@"
        ;;
    "-g" | "--get" | "--get-value")
        ACTION="GET-VALUE"
        get_value "$@"
        ;;
    *)
        echo "Unknown action."
        ;;
esac

