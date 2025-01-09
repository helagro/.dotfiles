# ------------------------- VARIABLES ------------------------ #

# Colors
BLUE='\033[34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
NORMAL='\033[0;39m'

# Inputs
do_es=false
filter=""
input="#inbox"
plain=false

# ------------------------- FUNCTIONS ------------------------ #

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

# ------------------------ EXPAND FLAGS ----------------------- #

expanded_args=()
for arg in "$@"; do
    if [[ "$arg" =~ ^-([eFhp]+)$ && ! "$arg" =~ ^-- ]]; then
        # Extract flags without using BASH_REMATCH
        flags="${arg:1}"
        for ((i = 0; i < ${#flags}; i++)); do
            expanded_args+=("-${flags:i:1}")
        done
    else
        expanded_args+=("$arg")
    fi
done

# Replace original arguments with expanded ones
set -- "${expanded_args[@]}"

# ------------------------- PARSE ARGUMENTS ------------------------ #

while [[ $# -gt 0 ]]; do
    case "$1" in
    -e | --es)
        do_es=true
        shift 1
        ;;
    -p | --plain)
        plain=true
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
        echo "Usage: tdl [ --es | -F <filter> | -h | -p ] [ <input> ]"
        exit 0
        ;;
    *)
        if [[ "$input" == "#inbox" ]]; then
            input=$(echo "$1" | sed 's/:/#/g')
            shift
        else
            echo "Unknown option: $1"
            exit 1
        fi
        ;;
    esac
done

# ---------------------------- RUN --------------------------- #

# if input contains a slash, list all tasks and grep instead
if [[ "$1" == *"/"* ]]; then
    output=$(todoist --indent list | grep "$input")
else
    output="$(todoist --indent list --filter "$input")"
fi

# ---------------------------- ES ---------------------------- #

if [[ "$do_es" == true ]]; then

    output_copy="$output"
    output=""

    # Loop through each line of output
    while IFS= read -r line; do

        if echo "$line" | awk -v today="$(date +%Y-%m-%d)" '
            {
                for (i=1; i<=NF; i++) {
                    if (substr($i, 1, 3) == "ES-" && substr($i, 4) > today) {
                        exit 1;
                    }
                }
            }'; then

            if [[ -n "$output" ]]; then
                output+="\n"
            fi

            output+="$line"
        fi

    done <<<"$output_copy"
fi

# -------------------------- FILTER -------------------------- #

if [[ -n "$filter" ]]; then
    output=$(echo "$output" | grep -vE "$filter")
fi

# -------------------------- OUTPUT -------------------------- #

if [[ "$plain" == true ]]; then
    echo "$output"
else
    echo "$output" | colorize
fi
