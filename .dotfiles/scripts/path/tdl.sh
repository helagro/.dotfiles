BLUE='\033[34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

RESET='\033[0m'
NORMAL='\033[0;39m'

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

# defaults to Inbox if no previous project
if [ -n "$1" ]; then
    input=$(echo "$1" | sed 's/:/#/g')
else
    input="#inbox"
fi

# if input contains a slash, list all tasks and grep instead
if [[ "$1" == *"/"* ]]; then
    output=$(todoist --indent list | grep "$input")
else
    output="$(todoist --indent list --filter "$input")"
fi

echo "$output" | colorize
