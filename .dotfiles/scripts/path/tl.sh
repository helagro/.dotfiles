#!/bin/zsh

do_newline=true
if [[ $1 == "-N" ]]; then
    do_newline=false
    shift
fi

params="${(j:/:)@}"
url="$TOOLS_URL/$params"
content=$(curl -H "Authorization: Bearer $A75H" -s "$url" -b "id=u3o8hiefo")
return_code=$?

if [ "$return_code" -ne 0 ]; then
    exit "$return_code"
fi

printf '%s' "$content" | rat.sh -pPl "json"
$do_newline && echo || :