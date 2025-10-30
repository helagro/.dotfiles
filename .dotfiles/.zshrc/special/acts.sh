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

local_online_tools="$HOME/Developer/server-app"

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

# User Facing
calc=1

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
                acts "$act_filter"
            else
                selection=$(acts "$act_filter" | fzf)
            fi
        else
            if [[ $calc == 1 ]]; then
                carg="-c"
            else
                carg=""
            fi


            selection=$(tdl "$filter" $carg -p | colorize | fzf)
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
            update=$(echo "$selection" | tr -s '[:space:]' ' ' | sed 's/^[0-9]*\ //' | sed 's/p4//')

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
        (
            echo "$selection" | in.sh
        )

        found_match=true
    fi


    if [[ $action == *"u"* || $action == *"m"* || $action == *"d"* || $action == *"e"* ]]; then
        (
            echo "$selection" | while read -r select_item; do
                if [[ $action == *"e"* ]]; then
                    local command=$(
                        echo "$select_item" | 
                        tr -s '[:space:]' ' ' | # Remove spaces
                        sed 's/^[0-9]*\ //' | # Remove ID
                        sed 's/#\([A-Za-z0-9/]*\)//' | # Remove project
                        sed 's/p[0-9]//' | # Remove priority
                        sed 's/@[A-Za-z0-9_/-]*//g' # Remove tags
                    )

                    eval "$command"
                fi
                
                if [[ "$action" == *"d"* ]]; then
                    local id=$(echo "$select_item" | grep -o '^[0-9]*')
                    close "$id" &
                    
                elif [[ "$action" == *"u"* ]]; then
                    # NOTE - Removes project and p4 priority
                    do_update "$(echo "$select_item" | sed 's/#\([A-Za-z0-9/]*\)//' | sed 's/p4//')" &

                elif [[ "$action" == *"m"* ]]; then
                    do_update "$select_item" &
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
    elif [[ $action == *"S"* ]]; then
        act_sync
        found_match=true
    fi

    if [[ $action == *"M"* ]]; then
        return 2
    elif ! $found_match; then
        echo "functions - (a)dd, (d)elete, (e)xecute, (F|f)ilter, (i)nbox, (m)odify, (n)ext, (r)un, (S|s)ync, (u)pdate, (q)uit"
        echo "modifiers - (A)lt, (M)enu, (W)ait"
        echo "options - calc=$calc"
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

    if [[ $(wc -l <<<"$selection") -gt 1 ]]; then
        # NOTE - Removes long spaces and IDs
        item=$(echo "$1" | tr -s '[:space:]' ' ' | sed 's/^[0-9]*\ //')
        item="$item $update"
    else
        item="$update"
    fi

    if [ -n "$item" ]; then
        # Very neccessary, some runaway otherwise
        local item_copy="$(echo "$item" | sed -E 's/(#[a-zA-Z]+)\/[a-zA-Z]+/\1/g')"

        nohup a.sh "$item_copy" &>/dev/null
        close "$id"

        item_copy=""
    else
        echo "WARN - empty item, ignoring"
    fi
}

# ==================================== ACT =================================== #

function act_td_filter {
    if [ $(tdl -F '#run|/ph' :$1 | wc -l) -le $2 ]; then
        echo "$3" | grep -v "$1^"
        print -n -u2 "$1, "
    else
        echo "$3"
    fi
}

function acts {
    local query=$(echo "$*" | tr ' ' '/')

    local output=$(
        cd $local_online_tools/dist/routes/act
        NODE_NO_WARNINGS=1 DO_LOG=false node index.js "$query"
    )

    # general filters ---------------------------------------------------- #

    print -n -u2 "\033[90mExcluding: "


    if ! $has_flashcards; then
        output=$(echo "$output" | grep -v 'flashcards^')
        print -n -u2 "flashcards, "
    fi

    if [[ $(obsi.sh 8 | wc -l) -lt 3 ]]; then
        output=$(echo "$output" | grep -v 'obsi^')
        print -n -u2 "obsi, "
    fi

    if ! state.sh -s 'tv'; then
        output=$(echo "$output" | grep -v 'review_tv^')
        print -n -u2 "review_tv, "
    fi

    # note filters --------------------------------------------------------------- #

    if [ $(ob b | wc -l) -le 4 ]; then
        output=$(echo "$output" | grep -v 'b^')
        print -n -u2 "b, "
    fi

    if [ $(ob p | wc -l) -ge 3 ]; then
        output=$(echo "$output" | grep -v 'plan^')
        print -n -u2 "plan, "
    fi

    # todoist filters ------------------------------------------------------------ #

    output=$(act_td_filter 'bdg' 2 "$output")
    output=$(act_td_filter 'by' 6 "$output")
    output=$(act_td_filter 'do' 5 "$output")
    output=$(act_td_filter 'eval' 4 "$output")
    output=$(act_td_filter 'inbox' 15 "$output")
    output=$(act_td_filter 'p1' 0 "$output")
    output=$(act_td_filter 'res' 7 "$output")
    output=$(act_td_filter 'u' 10 "$output")
    output=$(act_td_filter 'zz' 2 "$output")

    # calendar filters ----------------------------------------------------------- #

    local cal=$(short -m -N day tod)

    if echo $cal | grep -Fq " detach"; then
        output=$(echo "$output" | grep -v 'eve^')
        print -n -u2 "eve, "
    else
        if ! echo $cal | grep -Fq "full_detach"; then
            output=$(echo "$output" | grep -v 'cook^' | grep -v 'by^' | grep -v 'walk^')
            print -n -u2 "cook, by, walk, "

            if ! echo $cal | grep -Fq "bedtime"; then
                output=$(echo "$output" | grep -v 'floss^')
                print -n -u2 "floss, "
            fi
        fi
    fi

    # big filters ----------------------------------------------------------------- #

    if [[ " $@ " == *" b "* ]]; then
        ob b | while read -r break_item; do
            local item=$(echo "$break_item" | grep -oE '[[:alnum:]_]([[:alnum:]_]| )+$')

            if [[ -z "$item" ]]; then
                continue
            fi

            if printf "%s\n" "$output" | grep -qF "$item"; then
                print -n -u2 "$item, "
                output=$(echo "$output" | grep -v "$item")
            fi
        done
    fi

    # print ------------------------------------------------------ #

    print -u2 "\033[0m"
    echo $output | rat.sh -pPl "json" | $HOME/.dotfiles/scripts/secret/act_highlight.sh

    # sync ----------------------------------------------------------------------- #

    if rand 3 >/dev/null; then
        act_sync &
    fi
}

function act_sync {
    local table=$(curl -s --connect-timeout 2 "$MY_CONFIG_URL/server-app/act.tsv")

    if [ -n "$table" ]; then
        echo "$table" >$local_online_tools/data/act.tsv
        print -u2 "Updated act.tsv"
    else
        print -u2 "Failed to update act.tsv"
    fi
}