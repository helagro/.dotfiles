#!/bin/zsh
file_path="$HOME/.dotfiles/tmp/a.txt"
vault="$HOME/vault"

# -------------------------- PROCESS ------------------------- #

function process {
    if [ -z "$1" ]; then
        return 1
    fi

    if [[ "$DISABLED_TD_APP_ITEMS" == *"$1"* ]]; then
        return 0
    fi

    echo "$1" # For logging

    # Do process
    (
        process_local "$1" ||
            process_server "$1" ||
            process_todoist_cli "$1"
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
        echo "$escaped_input" >>"$vault/local/in.md"
        echo "Added directly to local vault"
        return 0
    else
        return 1
    fi
}

function process_server {
    # return 1 # Disable server processing

    local resCode=$(curl -s -b "a75h=$A75H" -o /dev/null -w "%{http_code}" -X POST -d "$1" $TDA_URL)

    return $((resCode != 200))
}

function process_todoist_cli {
    # return 1 # Disable todoist cli processing

    todoist q "$1" 2>/dev/null
    return $?
}

# --------------------------- UPLOAD -------------------------- #

function upload_stored {
    file_content=$(cat "$file_path")
    >$file_path

    echo "$file_content" | while IFS= read -r line; do
        process "$line"
    done
}

# --------------------------- START -------------------------- #

if process "$@"; then
    upload_stored
fi
