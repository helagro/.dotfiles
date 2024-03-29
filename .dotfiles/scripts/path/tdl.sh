function alt_lines {
    awk 'NR%2==0 {printf "\033[0;31m%s\033[0m\n", $0} NR%2==1 {printf "\033[0;39m%s\033[0m\n", $0}'
}

# if no input, defaults to #inbox
if [ -z "$2" ]; then
    input="#inbox"
fi

input=$(echo "$2" | sed 's/:/#/g')

# if zt on, add no p3 filter
if [ "$1" == "0" ]; then
    input="$input & !p3"
fi

# if input contains a slash, list all tasks and grep instead
if [[ "$2" == *"/"* ]]; then
    output=$(todoist --indent list | grep "$input")
else
    output="$(todoist --indent list --filter "$input")"
fi

# if zt on, remove @zit
if [ "$1" == "0" ]; then
    output=$(echo "$output" | grep -v "@zt")
    output=$(echo "$output" | grep -v "@time")
fi

echo "$output" | alt_lines
