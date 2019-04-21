#!/usr/bin/env bash
#
# Show the list of questons of a specific Slido event
#
#/ Usage:
#/   ./show-questionlist.sh -i <event_uuid> -t <auth_token> [-n <nb_of_questions> -o [top|newest]]
#/
#/ Options:
#/   -i             Event uuid
#/   -t             User auth token
#/   -n             (optional) List max. number of questions, default value: 30
#/   -o             (optional) Sort by "top" or "newest", default value: top
#/   -h, --help     Display this help message

usage() {
    # Display usage message
    grep '^#/' "$0" | cut -c4-
    exit 0
}

set_var() {
    # Declare variables used in script
    [[ -z $_QUESTION_ORDER ]] && _QUESTION_ORDER="top"
    [[ -z $_QUESTION_NUMBER ]] && _QUESTION_NUMBER="30"

    _HOST="https://app2.sli.do"
    _CURL_URL="${_HOST}/api/v0.5/events/${_EVENT_UUID}/questions?path=%2Fquestions&sort=${_QUESTION_ORDER}&limit=${_QUESTION_NUMBER}"
    _CURL_AUTH="Authorization: Bearer $_USER_AUTH"
}

get_args() {
    # Declare arguments
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":i:t:n:o:" opt; do
        case $opt in
            i)
                _EVENT_UUID="$OPTARG"
                ;;
            t)
                _USER_AUTH="$OPTARG"
                ;;
            n)
                _QUESTION_NUMBER="$OPTARG"
                ;;
            o)
                _QUESTION_ORDER="$OPTARG"
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
}

show_questions() {
    # Curl questions from slido
    $_CURL -sSX GET "$_CURL_URL" -H "$_CURL_AUTH" -H 'cache-control: no-cache' | $_JQ .
}

main() {
    check_command
    get_args "$@"
    check_args
    set_var
    show_questions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
