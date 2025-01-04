#!/bin/zsh

# ------------------------- VARIABLES ------------------------ #

BLUE='\033[34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
NORMAL='\033[0;39m'

source $HOME/.dotfiles/.zshrc/shared.sh
td s
td l -f "$project" >$HOME/.dotfiles/logs/inbox.log

project="#inbox"

if [ -z "$1" ]; then
    echo "No project specified, using default: $project"
else
    project="$1"
fi

# ------------------------- FUNCTIONS ------------------------ #

function colorize {
    awk -v blue="$BLUE" -v red="$RED" -v normal="$NORMAL" -v reset="$RESET" -v yellow="$YELLOW" -v green="$GREEN" '
    {
        gsub(/ p1 /, yellow "&" normal)
        gsub(/ p2 /, green "&" normal)
        gsub(/ p3 /, blue "&" normal)
        printf "%s%s%s\n", normal, $0, reset
    }'
}

function do_update {
    local id=$(echo "$1" | grep -o '^[0-9]*')
    item=$(echo "$1" | sed 's/^[0-9]*//' | sed 's/#\([A-Za-z0-9/]*\)//' | sed 's/p[0-9]//' | tr -s '[:space:]' ' ')

    vared item

    if [ -n "$item" ]; then
        (nohup a.sh "$item" >>$HOME/.dotfiles/logs/a.log 2>&1 &)
        tdc "$id"
    else
        echo "WARN - empty item, ignoring"
    fi
}

td l -f "$project" | while IFS= read -r line; do
    printf "$(echo "$line" | colorize) -:"
    read action </dev/tty

    if [[ "$action" == "d" ]]; then
        tdc "$line"
    elif [[ "$action" == "u" ]]; then
        do_update "$line"
    elif [[ "$action" == "q" ]]; then
        break
    elif [[ "$action" == "s" ]]; then
        continue
    else
        echo "(d)elete, (u)pdate, (s)kip (q)uit"
    fi

done
