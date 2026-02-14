#!/bin/zsh

# ------------------------- VARIABLES ------------------------ #

LATER_TASKS_INIT=$( cat $HOME/.dotfiles/tmp/later.txt | wc -l | tr -d '[:space:]' )
if [[ $? -ne 0 ]]; then
    touch $HOME/.dotfiles/tmp/later.txt
    LATER_TASKS_INIT=0
fi

# Colors
BLUE='\033[34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
NORMAL='\033[0;39m'

# --------------------------- SETUP -------------------------- #

if [[ -t 0 ]]; then # Run from terminal
    
    # Choose project
    project="#inbox"
    if [ -n "$1" ]; then
        project="$1"
    fi
    echo "Using project $project"

    todoist s
    task_string=$(todoist l -f "$project")

else # Read from pipe
    task_string=$(cat)
fi

readonly task_string

# ------------------------- FUNCTIONS ------------------------ #

function menu {
    
    # Print prompt
    local task=$(echo "$line" | sed 's/%/%%/g' | colorize)
    local curr_later_tasks=$( cat $HOME/.dotfiles/tmp/later.txt | wc -l | tr -d '[:space:]' )
    local later_tasks_added=$((curr_later_tasks - LATER_TASKS_INIT))

    if [[ "$later_tasks_added" -gt 0 ]]; then
        printf "\033[33m($(printf "%02d" $amt_left))\033[0m $task \033[33m($later_tasks_added):\033[0m"
    else
        printf "\033[33m($(printf "%02d" $amt_left))\033[0m $task \033[33m-:\033[0m"
    fi
    
    # Take input
    local input="$1"
    local id=$(td.sh x id "$input")
    local content=$(td.sh x no_id "$input")
    
    read action </dev/tty

    # IFs through actions
    if [[ "$action" == "d" ]]; then
        close "$id" &
        
    elif [[ "$action" == "u" ]]; then
        # NOTE - Removes project and p4 priority
        do_update "$id" "$(echo "$content" | sed 's/#\([A-Za-z0-9/]*\)//' | sed 's/p4//')"
    elif [[ "$action" == "m" ]]; then
        do_update "$id" "$content"
    elif [[ "$action" == "q" ]]; then
        exit 0
    elif [[ "$action" == "s" || "$action" == "n" ]]; then
        return
    elif [[ "$action" == "c" ]]; then
        echo "$content" | pbcopy
        close "$id" &

    else
        echo "(d)elete, (u)pdate, (m)modify, (n)ext, (c)opy, (q)uit"
        menu "$input" # NOTE - recursion
    fi
}

function colorize {
    awk -v blue="$BLUE" -v red="$RED" -v normal="$NORMAL" -v reset="$RESET" -v yellow="$YELLOW" -v green="$GREEN" '
    {
        gsub(/ p1 /, red "&" normal)
        gsub(/ p2 /, green "&" normal)
        gsub(/ p3 /, blue "&" normal)
        printf "%s%s%s\n", normal, $0, reset
    }'
}

# -------------------------- ACTIONS ------------------------- #

function close {
    if ping -c 1 -t 1 8.8.8.8 &>/dev/null; then
        (nohup todoist c "$1" >/dev/null 2>&1 &)
    else
        python3 $MY_SCRIPTS/lang/python/later.py "tdc $1" 
    fi
}

function do_update {

    # Parse parts
    local id=$1
    local content=$2

    # NOTE - Removes long spaces and IDs
    item=$(print "$content" | tr -s '[:space:]' ' ')

    vared -p " " item </dev/tty

    if [ -n "$item" ]; then
        # Very neccessary, some runaway otherwise
        local item_copy="$(echo "$item" | sed -E 's/(#[a-zA-Z]+)\/[a-zA-Z]+/\1/g')"

        (nohup a.sh "$item_copy" &>/dev/null &)
        item_copy=""
        close "$id" &
    else
        echo "WARN - empty item, ignoring"
    fi
}

# --------------------------- RUN -------------------------- #

amt_left=$(echo "$task_string" | wc -l | tr -d '[:space:]')
tasks=("${(f)task_string}")

IFS=$'\n'
for line in "${tasks[@]}"; do
    if [[ -z "$line" ]]; then
        continue
    fi
    
    menu "$line"
    amt_left=$((amt_left - 1))
done

echo "\nYou've reached inbox zero!"
