#!/bin/zsh

# NOTE - Needs work without sourcing main

file_path="$HOME/.dotfiles/tmp/a.txt"
vault="$HOME/vault"
did_local=false

# -------------------------- PROCESS ------------------------- #

function process {

    # Check conditions
    [ -z "$1" ] && return 1
    [[ "$DISABLED_TD_APP_ITEMS" == *"$1"* ]] && return 0

    echo "$1" # For logging

    # Do process local
    if process_local "$1"; then
        did_local=true
        return 0
    else
        did_local=false
    fi

    # Do process
    (
        process_server "$1" ||
            process_todoist_cli "$1 @alt"
    ) && return 0

    echo "$1" >>"$file_path"
    return 1
}

function process_local {
    # return 1 # Disable local processing

    (! command -v ob.sh >/dev/null 2>&1 || [ ! -e "$vault" ]) && return 1

    local tag=$(echo "$1" | grep -o '#\w\+')
    local escaped_input=$(echo "$1" | sed 's/#/\\#/g')

    if ob.sh "${tag#?}" >/dev/null 2>&1; then
        echo "$escaped_input" >>"$vault/_/local/in.md"
        return 0
    else
        return 1
    fi
}

function process_server {
    # return 1 # Disable server processing

    [ -z "$TDA_URL" ] && echo "Missing TDA_URL" && return 1

    local json_payload=$(python3 "$HOME/.dotfiles/scripts/lang/python/addMetadata.py" "$1")
    if [ $? -eq 0 ]; then
        local resCode=$(curl -s -b "a75h=$A75H" -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST --data-raw "$json_payload" $TDA_URL)
    else
        local resCode=$(curl -s -b "a75h=$A75H" -o /dev/null -w "%{http_code}" -X POST --data-raw "$1" $TDA_URL)
    fi

    return $((resCode != 200))
}

function process_todoist_cli {
    # return 1 # Disable todoist cli processing

    if ! command -v todoist >/dev/null 2>&1; then
        return 1
    fi

    todoist q "$1" 2>/dev/null
    return $?
}

# --------------------------- UPLOAD -------------------------- #

function upload_stored {
    if [ ! -e "$file_path" ]; then
        return 0
    fi

    file_content=$(cat "$file_path")
    echo -n "" >$file_path

    echo "$file_content" | while IFS= read -r line; do
        process "$line"
    done
}

# --------------------------- START -------------------------- #

for input in ${(s:&& :)*}; do
    (
        if process "$input" && [ "$did_local" = false ]; then
            upload_stored
        fi
    ) | $HOME/.dotfiles/scripts/lang/shell/utils/log.sh -sof a
done


exit 0
