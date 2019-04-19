#!/usr/bin/env bash
#
# This script will vote a slido queston
#
#/ Usage:
#/   ./vote_question.sh -i <event_id> -t <auth_token> -q <question_id> [-r]
#/
#/ Options:
#/   -i             Event uuid
#/   -t             User auth token
#/   -q             Question id
#/   -r             (optional) Revoke vote
#/   -h, --help     Display this help message

usage() {
    # Display usage message
    grep '^#/' "$0" | cut -c4-
    exit 0
}

set_var() {
    # Declare variables used in script
    [[ -z $_REVOKE_VOTE ]] && _REVOKE_VOTE=false

    _HOST="https://app2.sli.do"
    _CURL_URL="${_HOST}/api/v0.5/events/${_EVENT_UUID}/questions/${_QUESTION_ID}/like"
    _CURL_AUTH="Authorization: Bearer $_USER_AUTH"
}

get_args() {
    # Declare arguments
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":ri:t:q:" opt; do
        case $opt in
            i)
                _EVENT_UUID="$OPTARG"
                ;;
            t)
                _USER_AUTH="$OPTARG"
                ;;
            q)
                _QUESTION_ID="$OPTARG"
                ;;
            r)
                _REVOKE_VOTE=true
                ;;
            h)
                usage
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                usage
                ;;
        esac
    done
}

check_command() {
    # Check if required command exists
    _CURL=$(command -v curl)
    if [[ ! "$_CURL" ]]; then
        echo "'curl' command dosen't exist!" && exit 1
    fi

    _JQ=$(command -v jq)
    if [[ ! "$_JQ" ]]; then
        echo "'jq' command dosen't exist!" && exit 1
    fi
}

check_args() {
    # Check event uuid and auth token are set
    if [[ -z "$_EVENT_UUID" ]]; then
        echo "Event uuid '-i' is not set!"
        usage
    fi
    if [[ -z "$_USER_AUTH" ]]; then
        echo "User auth token '-t' is not set!"
        usage
    fi
    if [[ -z "$_QUESTION_ID" ]]; then
        echo "Question id '-q' is not set!"
        usage
    fi
}

vote_question() {
    # Vote question
    if [[ $_REVOKE_VOTE == true ]]; then
        $_CURL -X POST "$_CURL_URL" -H "$_CURL_AUTH" -H 'cache-control: no-cache' -H 'Content-Type: application/json' -d '{"score":0}'

    else
        $_CURL -X POST "$_CURL_URL" -H "$_CURL_AUTH" -H 'cache-control: no-cache' -H 'Content-Type: application/json' -d '{"score":1}'
    fi
}

main() {
    check_command
    get_args "$@"
    check_args
    set_var
    vote_question
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
