#!/bin/zsh

# ------------------------- VARIABLES ------------------------ #

# Colors
BLUE='\033[34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
NORMAL='\033[0;39m'

# --------------------------- SETUP -------------------------- #

source $HOME/.dotfiles/.zshrc/shared.sh
td s

td l -f "$project" >$HOME/.dotfiles/logs/inbox.log # For logging

# Choose project
project="#inbox"
if [ -n "$1" ]; then
    project="$1"
fi
echo "$project"

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

function menu {
    printf "$(echo "$line" | colorize) -:"

    # Take input
    local input="$1"
    read action </dev/tty

    # IFs through actions
    if [[ "$action" == "d" ]]; then
        local id=$(echo "$1" | grep -o '^[0-9]*')
        tdc "$id"
    elif [[ "$action" == "u" ]]; then
        do_update "$(echo "$input" | sed 's/#\([A-Za-z0-9/]*\)//' | sed 's/p4//')"
    elif [[ "$action" == "m" ]]; then
        do_update "$input"
    elif [[ "$action" == "q" ]]; then
        exit 0
    elif [[ "$action" == "s" ]]; then
        continue
    else
        echo "(d)elete, (u)pdate, (m)modify, (s)kip, (q)uit"
        menu "$input" # NOTE - recursion
    fi
}

function do_update {

    # Parse parts
    local id=$(echo "$1" | grep -o '^[0-9]*')
    item=$(echo "$1" | sed 's/^[0-9]*//' | tr -s '[:space:]' ' ')

    vared item </dev/tty

    if [ -n "$item" ]; then
        # Very neccessary, some runaway otherwise
        local item_copy="$(echo "$item" | sed -E 's/(#[a-zA-Z]+)\/[a-zA-Z]+/\1/g')"

        (nohup a.sh "$item_copy" >>$HOME/.dotfiles/logs/a.log 2>&1 &)
        item_copy=""
        tdc "$id"
    else
        echo "WARN - empty item, ignoring"
    fi
}

IFS=$'\n'
for line in $(td l -f "$project"); do
    menu "$line"
done

echo "You've reached inbox zero!"
