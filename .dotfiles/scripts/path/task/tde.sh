#!/bin/zsh

clear
alias tdl="$MY_SCRIPTS/lang/shell/task/tdl.sh"
filter="$1"

# ================================= FUNCTIONS ================================ #

function menu {
        
    # Take input
    printf "Action: "
    local input="$1"
    read action </dev/tty

    if [[ "$action" == "q" ]]; then
        exit 0
    elif [[ $action == "s" ]]; then
        todoist sync
        return
    elif [[ "$action" == "n" ]]; then
        return
    elif [[ $action == "f" ]]; then
        vared -p "Filter: " filter </dev/tty
        return
    elif [[ $action == "u" || $action == "m" ]]; then
        update=""
        vared -p "Update: " update </dev/tty
    fi


    echo "$selection" | while read -r item; do
        if [[ "$action" == "d" ]]; then
            local id=$(echo "$item" | grep -o '^[0-9]*')
            close "$id"
            
        elif [[ "$action" == "u" ]]; then
            # NOTE - Removes project and p4 priority
            do_update "$(echo "$item" | sed 's/#\([A-Za-z0-9/]*\)//' | sed 's/p4//')"

        elif [[ "$action" == "m" ]]; then
            do_update "$item"

        else
            echo "(d)elete, (u)pdate, (m)modify, (n)ext, (q)uit"
            menu # NOTE - recursion
            return
        fi
    done

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
        todoist c "$1" >/dev/null
    else
        python3 $MY_SCRIPTS/lang/python/later.py "tdc $1" 
    fi
}

function do_update {

    # Parse parts
    local id=$(echo "$1" | grep -o '^[0-9]*')

    # NOTE - Removes long spaces and IDs
    item=$(echo "$1" | tr -s '[:space:]' ' ' | sed 's/^[0-9]*\ //')
    item="$item $update"

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

# ==================================== RUN =================================== #

while :; do
    selection=$(tdl "$filter" -p | peco)

    echo "$selection" | colorize
    menu
    echo ""
done