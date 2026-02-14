# ============================== USER CONTANTS ============================== #

# Busy - Easy
busez="(!#then)&(#bdg|#zz|@ez)&!p3"
print -s -- '$busez'

i="(tod|od|p1)"
print -s -- '$i'

in="#inbox"
print -s -- '$in'

u="#u&!#run"
print -s -- '$u'

# ================================= CONSTANTS ================================ #

export FZF_DEFAULT_OPTS='-m --cycle --ansi --no-sort --layout=reverse-list --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'


# Colors
BLUE='\033[34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
NORMAL='\033[0;39m'

# ================================= VARIABLES ================================ #

alt=false
do_act=false
new_task=""

act_filter=""
filter=""


# ================================= FUNCTIONS ================================ #

function on_tab {
    clear
    run
}

function run {
    menu

    while :; do
        if $do_act; then
            if $alt; then
                selection=""
                acts.sh "$act_filter"
            else
                local list=$(acts.sh "$act_filter")
                selection=$(echo "$list" | fzf)
            fi
        else
            (map.sh -s 'opt.no_calc' || map.sh -s 's.off') && carg="" || carg="-c"

            local tasks=$(tdl "$filter" $carg -p)
            local filtered_ids=$(map.sh -m acts | jq -r 'join("|")')

            if [[ -n "$filtered_ids" && -n "$tasks" ]]; then
                tasks=$(echo "$tasks" | grep -Ev "^($filtered_ids)\ ")
            fi

            selection=$(echo "$tasks" | colorize | fzf )
        fi

        echo "$selection" | colorize

        while :; do
            menu
            local ret=$?

            if [[ $ret -eq 1 ]]; then
                return
            elif [[ $ret -eq 2 ]]; then
                continue
            else
                break
            fi
        done
        
        echo ''
    done
}

function menu {
    local found_match=false
        
    # Take input
    printf "Action: "
    local input="$1"
    read action </dev/tty

    local await_completion=true
    [[ $action == *"w"* ]] && await_completion=true
    [[ $action == *"W"* ]] && await_completion=false

    alt=false
    [[ $action == *"A"* ]] && alt=true

    if [[ "$action" == *"q"* ]]; then
        return 1
    elif [[ "$action" == *"n"* ]]; then
        return
    elif [[ $action == *"f"* ]]; then
        vared -p "Filter: " filter </dev/tty
        
        local escaped_filter=$(echo "$filter" | sed -E \
            -e "s/'/\\'/g" \
            -e 's/`/\\`/g' \
            -e 's/"/\\"/g')
        filter=$(eval echo \"$escaped_filter\" | tr -d '\\')

        print -s -- "$filter"
        print -s -- " "

        found_match=true
        do_act=false
    elif [[ $action == *"a"* ]]; then
        vared -p "New task: " new_task </dev/tty
        (
            a.sh "$new_task" >/dev/null &
            $await_completion && wait
        )
        found_match=true

    elif [[ $action == *"c"* ]]; then
        echo -n "" | pbcopy
        
    elif [[ $action == *"F"* ]]; then
        vared -p "Act filter: " act_filter </dev/tty

        print -s -- "$act_filter"
        print -s -- " "
        
        found_match=true
        do_act=true
    elif [[ $action == *"u"* || $action == *"m"* ]]; then

        if [[ $(wc -l <<<"$selection") -gt 1 ]]; then
            update=""
        else
            update=$(td.sh x no_id "$selection" |  sed 's/p4//' | td.sh s)

            if [[ $action == *"u"* ]]; then
                update=$(echo "$update" | sed 's/#\([A-Za-z0-9/]*\)//')
            fi
            found_match=true
        fi

        vared -p "Update: " update </dev/tty
    elif [[ $action == *"r"* ]]; then
        local command=""
        vared -p "Run: " command </dev/tty

        if [[ -n "$command" ]]; then
            eval "$command"
        fi
        found_match=true

    elif [[ $action == *"i"* ]]; then
        echo
        (
            echo "$selection" | in.sh
        )

        found_match=true
    fi


    if [[ $action =~ [umdec] ]]; then
        (
            echo "$selection" | while read -r select_item; do
                local id=$(td.sh x id "$select_item")
                local content=$(td.sh x no_id "$select_item" | td.sh s)

                local select_item_content=$(
                        echo "$content" | 
                        sed 's/#\([A-Za-z0-9/]*\)//' | # Remove project
                        sed 's/p[0-9]//' | # Remove priority
                        sed 's/@[A-Za-z0-9_/-]*//g' # Remove tags
                    )

                if [[ $action == *"e"* ]]; then
                    eval "$select_item_content"
                elif [[ $action == *"c"* ]]; then
                    local prev_clipboard=$(pbpaste)
                    [[ -n $prev_clipboard ]] && prev_clipboard+="\n"
                    print -n "$prev_clipboard$(print -n $select_item_content)" | pbcopy
                fi
                
                if [[ "$action" == *"d"* ]]; then
                    close "$id" &
                    
                elif [[ "$action" == *"u"* ]]; then
                    # NOTE - Removes project and p4 priority
                    do_update "$id" "$(echo "$content" | sed 's/#\([A-Za-z0-9/]*\)//' | sed 's/p4//')" &

                elif [[ "$action" == *"m"* ]]; then
                    do_update "$id" "$(echo "$content" | sed 's/p4//')" &
                fi
            done

            $await_completion && wait
        )
        
        found_match=true
    fi

    if [[ $action == *"s"* ]]; then
        (
            echo "Syncing..."
            todoist sync &
            $await_completion && wait
        )
        found_match=true

        map.sh -m set acts "[]" 2>/dev/null
    elif [[ $action == *"S"* ]]; then
        act_sync
        found_match=true
    fi

    if [[ $action == *"C"* ]]; then
        clear
        return 2
    elif [[ $action == *"M"* ]]; then
        return 2
    elif ! $found_match; then
        echo "functions - (a)dd, (c)opy, (d)elete, (e)xecute, (F|f)ilter, (i)nbox, (m)odify, (n)ext, (r)un, (S|s)ync, (u)pdate, (q)uit"
        echo "modifiers - (A)lt, (C)lear (M)enu, (W|w)ait"
        menu # NOTE - recursion
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


function do_update {

    # Parse parts
    local id=$1
    local content=$2

    if [[ $(wc -l <<<"$selection") -gt 1 ]]; then
        item="$content $update"
    else
        item="$update"
    fi

    if [ -n "$item" ]; then
        # Very neccessary, some runaway otherwise
        local item_copy="$(echo "$item" | sed -E 's/(#[a-zA-Z]+)\/[a-zA-Z]+/\1/g' | td.sh s)"

        nohup a.sh "$item_copy" &>/dev/null
        close "$id"

        item_copy=""
    else
        echo "WARN - empty item, ignoring"
    fi
}

function close {
    if [[ -n "$1" ]]; then
        map.sh -m add acts "$1" 2>/dev/null
        tdc "$1" >/dev/null &
    fi
}
