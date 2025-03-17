#!/bin/zsh

todoist l -f "#run&no date" | to_color.sh yellow

# Removes ansi codes from stdin
tasks_str=$(todoist l -f "#run" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')

tasks=("${(f)tasks_str}")

IFS=$'\n'
for line in "${tasks[@]}"; do
    if [[ -z "$line" ]]; then
        continue
    fi

    if echo "$line" | grep -sq "$(date +'%y/%m/%d')"; then

        task_str=$(echo "$line" | sed -E 's|^.*#run\/[a-zA-Z0-9]*||' | sed 's/:/#/g')
        task_id=$(echo "$line" | grep -o '^[0-9]*')
        
        echo "RAN: $task_str"
        a.sh "$task_str" > /dev/null
        todoist c "$task_id"
    fi
done
