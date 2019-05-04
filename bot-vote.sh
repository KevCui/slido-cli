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

main() {
    set_var
    read -rp "Slido event URL: " url
    data=$($_NODE "$_FETCH" "$url")
    uuid=${data%,*}
    token=${data##*,}

    $_SHOW -i "$uuid" -t "$token" | grep -E "(question_id|text)"
    read -rp "Question id: " id

    read -rp "Number of vote(s): " num
    file="./.tmp.$(date +%s)"
    for ((i = 0; i < "$num"; i++)); do
        $_NODE "$_FETCH" "$url" >> "$file" && echo "Fetched token $((i+1))"
    done

    while IFS='' read -r line || [[ -n "$line" ]]; do
        $_VOTE -i "$uuid" -t "${line##*,}" -q "$id"
    done < "$file"

    printf "\n\n"
    echo "Revoke vote(s)? Run command below:"
    echo "while IFS='' read -r line || [[ -n \"\$line\" ]]; do $_VOTE -i $uuid -t \"\${line##*,}\" -q $id -r; done < $file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
