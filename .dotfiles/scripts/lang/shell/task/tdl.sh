#!/bin/zsh

# ------------------------- VARIABLES ------------------------ #

# Colors
BLUE='\033[34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
NORMAL='\033[0;39m'

# Inputs
do_watch=false
filter=""
input=""
plain=false
computed=false

# ------------------------- PARSE ARGUMENTS ------------------------ #

set -- $($MY_SCRIPTS/lang/shell/expand_args.sh "$@")

while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --plain)
        plain=true
        shift 1
        ;;
    -c | --computed)
        computed=true
        shift 1
        ;;
    -F | --filter)
        filter="$2"

        if [[ -z "$filter" ]]; then
            echo "Missing filter"
            exit 1
        fi

        shift 2
        ;;
    -h | --help)
        printf 'Usage: tdl [options...] <todoist-filter>\n'
        printf " %-3s %-20s %s\n" "-F" "--filter" "Reverse grep filter with regex"
        printf " %-3s %-20s %s\n" "-p" "--plain" "Print plain text"
        printf " %-3s %-20s %s\n" "-c" "--computed" "Use computed filter"
        printf " %-3s %-20s %s\n" "-w" "--watch" "Watch for changes"
        printf " %-3s %-20s %s\n" "-h" "--help" "Show this help message"
        exit 0
        ;;
    -w | --watch)
        do_watch=true
        shift 1
        ;;
    *)
        if [[ -z $input ]]; then
            input=$(echo "$1" | sed 's/:/#/g')
            shift
        else
            echo "Unknown option: $1"
            exit 1
        fi
        ;;
    esac
done

# =============================== MAIN FUNCTIONS ============================== #

function load_tasks {
    # if input contains a slash, list all tasks and grep instead
    if [[ "$1" == *"/"* ]]; then
        todoist --indent list | grep "$input"
    else
        m_td_get "$input"
    fi
}

function main {
    tasks="$2"

    # filter --------------------------------------------------------------------- #

    if $computed; then
        if [[ -z "$filter" ]]; then
            filter="^a\Z" # Matches nothing
        fi

        if "$HOME/.dotfiles/scripts/path/state/state.sh" -s headache || $is_busy; then
            filter+="|(p3.*#bdg)"
        fi

        if "$HOME/.dotfiles/scripts/lang/shell/has_detached.sh"; then
            filter+="|@wake"
        fi
    fi

    if [[ -n "$filter" ]]; then
        tasks=$(echo "$tasks" | grep -vE "$filter")
    fi

    # output --------------------------------------------------------------------- #

    if $plain; then
        echo "$tasks"
    elif ! command -v todoist &>/dev/null; then
        echo '['
        echo "$tasks" | rat.sh -pPl json
        echo ']'
    else
        tasks=$(echo "$tasks" | add_line_nr)
        echo "$tasks" >"$HOME/.dotfiles/tmp/tdl.txt"
        echo "$tasks" | colorize
    fi
}

# ============================= HELPER FUNCTIONS ============================= #

function m_td_get {
    if command -v todoist &>/dev/null; then
        todoist --indent list --filter "$1"
    else
        curl -sX GET \
            https://api.todoist.com/rest/v2/tasks \
            -H "Authorization: Bearer $TODOIST_TOKEN" -G \
            --data-urlencode "filter=$1" | grep -E "content|priority|{|}|(\"id\":)|(\w$)"
    fi
}

function add_line_nr {
    i=1
    while IFS= read -r line; do
        printf "(%02d) %s\n" $i "$line"
        ((i++))
    done <<<"$tasks"
}

function colorize {
    awk -v blue="$BLUE" -v red="$RED" -v normal="$NORMAL" -v reset="$RESET" -v yellow="$YELLOW" -v green="$GREEN" '
    {
        if (NR % 2 == 0) {
            gsub(/ p1 /, yellow "&" red)
            gsub(/ p2 /, green "&" red)
            gsub(/ p3 /, blue "&" red)
            printf "%s%s%s\n", red, $0, reset
        } else {
            gsub(/ p1 /, yellow "&" normal)
            gsub(/ p2 /, green "&" normal)
            gsub(/ p3 /, blue "&" normal)
            printf "%s%s%s\n", normal, $0, reset
        }
    }'
}

# ==================================== RUN =================================== #

if $do_watch; then
    while true; do
        tasks=$(load_tasks)
        task_amt=$(echo "$tasks" | wc -l)

        if [[ "$task_amt" != "$last_task_amt" ]]; then
            last_task_amt=$task_amt
            clear
            date "+%F %T" | to_color.sh 'magenta'
            main "$input" "$tasks"
        fi

        sleep 2
    done
else
    tasks=$(load_tasks)
    main "$input" "$tasks"
fi
