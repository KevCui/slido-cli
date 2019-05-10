#!/usr/bin/env bash

set_var() {
    # Set global variables
    _FETCH="./fetch-slido-token.js"
    _SHOW="./show-questionlist.sh"
    _VOTE="./vote-question.sh"
    _SESSION="./.tmp.$(date +%s)"
    _NODE=$(command -v node)

    check_file "$_FETCH"
    check_file "$_SHOW"
    check_file "$_VOTE"
    check_command "$_NODE" "node"

    _URL=$(ask_for_url "$1")
    _UUID=$(get_uuid "$_URL")
    _TOKEN=$(get_last_token "$_URL")
    _EVENT=$(get_event_from_url "$_URL")
}

check_command() {
    # Check if required command exists
    if [[ ! "$1" ]]; then
        echo "$2 command dosen't exist!" && exit 1
    fi
}

check_url() {
    # Check if $1 is a valid slido URL or not
    if [[ "$1" != *"app.sli.do/event/"*"/live/questions"* ]]; then
        echo "Wrong Sli.do URL. Correct format should be: https://app.sli.do/event/<id>/live/questions" && exit 1
    fi
}

check_file() {
    # Check file if it exist
    if [[ ! -f "$1" ]]; then
        echo "Cannot find: $1"
        exit 1
    fi
}

get_event_from_url() {
    # Get slido event number from URL
    echo "$1" | sed -e 's/.*event\///;s/\/live.*$//'
}

get_token_num() {
    # Get current token number
    [[ ! -f "$1" ]] && touch "$1"
    wc -l < "$1"
}

tail_last_line() {
    # Get last n lines of token
    local file
    local num
    file=$(get_event_from_url "$1")
    num=$(get_token_num "$file")
    if [[ "$num" -eq 0 ]]; then
       $_NODE "$_FETCH" "$1" > "$file"
    fi
    tail -1 "$file"
}

get_uuid(){
    # Get UUID
    local line
    line=$(tail_last_line "$1")
    echo "${line%,*}"
}

get_last_token() {
    # Get last token
    local line
    line=$(tail_last_line "$1")
    echo "${line##*,}"
}

ask_for_url() {
    # Ask for slido question URL
    local url
    if [[ -z "$1" ]]; then
        read -rp "Slido event URL: " url
    else
        url="$1"
    fi
    check_url "$url"
    echo "$url"
}

ask_for_question_id() {
    # Ask for question id
    $_SHOW -i "$_UUID" -t "$_TOKEN" | grep -E "(question_id|text|score_positive)" >&2
    read -rp "Question id: " id
    echo "$id"
}

ask_for_number_of_votes() {
    # Ask for number of votes
    read -rp "Number of vote(s): " num

    local currnum
    currnum=$(get_token_num "$_EVENT")

    # Fetch tokens to meet required num
    if [[ "$num" -gt "$currnum" ]]; then
        for ((i = 0; i < "$((num-currnum))"; i++)); do
            echo "Fetching token $((i+1))"
            $_NODE "$_FETCH" "$_URL" >> "$_EVENT"
        done
    fi

    echo "$num"
}

prepare_session() {
    # Generate session file with num of tokens
    tail -n "$1" "$_EVENT" > "$_SESSION"
}

vote() {
    # Vote for qustions
    echo "Ready to vote $(get_token_num "$2") times..."
    while IFS='' read -r line || [[ -n "$line" ]]; do
        $_VOTE -i "$_UUID" -t "${line##*,}" -q "$1" >&2
    done < "$2"
}

print_revoke_command() {
    # Print revoke command
    printf "\n\n"
    echo "Revoke vote(s)? Run command below:"
    echo "while IFS='' read -r line || [[ -n \"\$line\" ]]; do $_VOTE -i $_UUID -t \"\${line##*,}\" -q $id -r; done < $_SESSION"
}

main() {
    set_var "$@"
    id=$(ask_for_question_id)
    num=$(ask_for_number_of_votes)
    prepare_session "$num"
    vote "$id" "$_SESSION"
    print_revoke_command
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
