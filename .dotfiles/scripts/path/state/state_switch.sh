#!/bin/zsh

state_json=$(map.sh s)
state_keys=($(map.sh s | jq -r 'keys[]'))

matches=""

while IFS= read -r line; do
    if [[ "$line" == *-IF* ]]; then
        for state in "${state_keys[@]}"; do
            state_val=$(echo $state_json | jq -r ".$state")

            if [[ "$line" =~ ".*-IF.* $state.*" ]] && $state_val; then
                matches+="$line\n"
                break
            elif [[ "$line" =~ ".*-IF.*!$state.*" ]] && ! $state_val; then
                matches+="$line\n"
                break
            fi
        done
    elif [ -n "$line" ] && [[ "$line" != "---" ]]; then
        matches+="$line\n"
    fi
done

echo -n $matches | awk '!seen[$0]++' | sed 's/- \[ \] //g'
