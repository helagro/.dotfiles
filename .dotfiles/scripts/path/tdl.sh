function alt_lines {
    awk 'NR%2==0 {printf "\033[0;31m%s\033[0m\n", $0} NR%2==1 {printf "\033[0;39m%s\033[0m\n", $0}'
}

# if no input, defaults to #inbox
if [ -z "$1" ]; then
    input="#inbox"
fi

input=$(echo "$1" | sed 's/:/#/g')

# if input contains a slash, list all tasks and grep instead
if [[ "$1" == *"/"* ]]; then
    output=$(todoist --indent list | grep "$input")
else
    output="$(todoist --indent list --filter "$input")"
fi

echo "$output" | alt_lines
