#!/bin/zsh
file_path="$HOME/.dotfiles/data/a.txt"

function process {
    if [ -z "$1" ]; then
        return 1
    fi

    if [[ "$DISABLED_TD_APP_ITEMS" == *"$1"* ]]; then
        return 0
    fi

    echo "$1"
    resCode=$(curl -s -b "a75h=$A75H" -o /dev/null -w "%{http_code}" -X POST -d "$1" $TDA_URL)

    if [ "$resCode" -eq 200 ]; then
        return 0
    fi

    if todoist q "$1" 2>/dev/null; then
        return 0
    fi

    echo "$1" >>"$file_path"
    return 1
}

function upload_stored {
    file_content=$(cat "$file_path")
    >$file_path

    echo "$file_content" | while IFS= read -r line; do
        process "$line"
    done
}

if process "$@"; then
    upload_stored
fi
