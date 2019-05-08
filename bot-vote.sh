#!/usr/bin/env bash

set_var() {
    _FETCH="./fetch-slido-token.js"
    _SHOW="./show-questionlist.sh"
    _VOTE="./vote-question.sh"
    _NODE=$(command -v node)

    check_file "$_FETCH"
    check_file "$_SHOW"
    check_file "$_VOTE"
}

check_file() {
    # Check file if it exist
    if [[ ! -f "$1" ]]; then
        echo "Cannot find: $1"
        exit 1
    fi
}

get_event_from_url() {
    echo "$1" | sed -e 's/.*event\///;s/\/live.*$//'
}

get_token_num() {
    [[ ! -f "$1" ]] && touch "$1"
    wc -l < $1
}

tail_last_line() {
    local file=$(get_event_from_url "$1")
    local num=$(get_token_num "$file")
    if [[ "$num" -eq 0 ]]; then
       $_NODE "$_FETCH" "$1" > $file
    fi
    tail -1 "$file"
}

get_uuid(){
    local line=$(tail_last_line "$1")
    echo ${line%,*}
}

get_last_token() {
    local line=$(tail_last_line "$1")
    echo ${line##*,}
}

main() {
    set_var

    read -rp "Slido event URL: " url
    uuid=$(get_uuid "$url")
    token=$(get_last_token "$url")
    event=$(get_event_from_url "$url")

    # ask for question id
    $_SHOW -i "$uuid" -t "$token" | grep -E "(question_id|text|score_positive)"
    read -rp "Question id: " id

    # ask for number of votes
    read -rp "Number of vote(s): " num
    currnum=$(get_token_num "$event")

    # fetch tokens to meet required num
    if [[ "$num" -gt "$currnum" ]]; then
        for ((i = 0; i < "$((num-currnum))"; i++)); do
            echo "Fetching token $((i+1))"
            $_NODE "$_FETCH" "$url" >> "$event"
        done
    fi

    # generate session file with num of tokens
    session="./.tmp.$(date +%s)"
    tail -n "$num" "$event" > $session

    echo "Ready to vote $(get_token_num "$session") times..."
    while IFS='' read -r line || [[ -n "$line" ]]; do
        $_VOTE -i "$uuid" -t "${line##*,}" -q "$id"
    done < "$session"

    # print revoke command
    printf "\n\n"
    echo "Revoke vote(s)? Run command below:"
    echo "while IFS='' read -r line || [[ -n \"\$line\" ]]; do $_VOTE -i $uuid -t \"\${line##*,}\" -q $id -r; done < $session"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
