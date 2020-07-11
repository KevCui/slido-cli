#!/usr/bin/env bash

if [[ -z "${1:-}" ]]; then
    echo "[ERROR] Missing input URL!" && exit 1
fi

_NUM=1
if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
    _NUM="$2"
fi

_CURL=$(command -v curl)
_HASH=$(sed -E 's/.*sli.do\/event\///' <<< "$1" | awk -F '/' '{print $1}')
_EVENT_UUID=$($_CURL -sS "https://app.sli.do/api/v0.5/events?hash=$_HASH" \
    -H 'Cache-control: no-cache, no-store' \
    | sed -E 's/.*"uuid":"//' \
    | awk -F '"' '{print $1}')

for (( i = 0; i < _NUM; i++ )); do
    _TOKEN=$($_CURL -sS "https://app.sli.do/api/v0.5/events/$_EVENT_UUID/auth?attempt=1" \
        -H 'Cache-control: no-cache, no-store' \
        -H 'Pragma: no-cache' --data-raw '{"granted_consents":[],"attrs":{"initialAppViewer":"browser--other"}}' \
        | sed -E 's/.*"access_token":"//' \
        | awk -F '"' '{print $1}')

    echo "$_EVENT_UUID,$_TOKEN"
done
