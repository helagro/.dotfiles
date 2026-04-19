#!/bin/zsh

# NOTE!! - Doesn't work for states not currently in map

state_json=$(map.sh s)
state_keys=($(echo $state_json | jq -r 'keys[]'))

matches=""

# ============================== MATCH FUNCTIONS ============================= #

function match_or {
    local line="$1"

    for state in "${state_keys[@]}"; do
        local state_val=$(echo $state_json | jq -r ".$state")

        if [[ "$line" =~ ".*-IF.* !$state.*" ]] && ! is_truthy "$state_val"; then
            echo "${line/\*-IF*/}\n"
            break
        elif [[ "$line" =~ ".*-IF.* $state.*" ]] && is_truthy "$state_val"; then
            echo "${line/\*-IF*/}\n"
            break
        fi
    done
}

function match_and {
    local line="$1"

    for state in "${state_keys[@]}"; do
        local state_val=$(echo "$state_json" | jq -r ".$state")

        if [[ "$line" =~ ".*-IF.* !$state.*" ]] && is_truthy "$state_val"; then
            return
        elif [[ "$line" =~ ".*-IF.* $state.*" ]] && ! is_truthy "$state_val"; then
            return
        fi
    done

    echo "${line/\*\*-IF*/}\n"
}

# ================================== HELPERS ================================= #

function is_truthy {
    [[ $1 == true || $1 -ge 1 ]]
}

# ==================================== EXECUTION =================================== #

while IFS= read -r line; do
    if [[ "$line" == *'**-IF'* ]]; then
        match_and "$line"

    elif [[ "$line" == *'*-IF'* ]]; then
        match_or "$line"
        
    elif [ -n "$line" ] && [[ "$line" != "---" ]]; then
        matches+="$line\n"
    fi
done

echo -n $matches | awk '!seen[$0]++' | sed 's/- \[ \] //g'
