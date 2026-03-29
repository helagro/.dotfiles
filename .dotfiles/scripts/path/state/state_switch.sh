#!/bin/zsh

state_json=$(map.sh s)
state_keys=($(echo $state_json | jq -r 'keys[]'))

matches=""

# ============================== MATCH FUNCTIONS ============================= #

function match_or {
    local line="$1"

    for state in "${state_keys[@]}"; do
        state_val=$(echo $state_json | jq -r ".$state")

        if [[ "$line" =~ ".*-IF.* $state.*" ]] && [[ $state_val == true || $state_val -ge 1 ]]; then
            echo "$line\n"
            break
        elif [[ "$line" =~ ".*-IF.*!$state.*" ]] && [[ $state_val == false || $state_val -le 0 ]]; then
            echo "$line\n"
            break
        fi
    done
}

function match_and {
    local line="$1"

    for state in "${state_keys[@]}"; do
        state_val=$(echo "$state_json" | jq -r ".$state")

        if [[ "$line" =~ ".*-IF.* $state.*" ]]; then
            if [[ ! ( $state_val == true || $state_val -ge 1 ) ]]; then
                return
            fi
        elif [[ "$line" =~ ".*-IF.*!$state.*" ]]; then
            if [[ ! ( $state_val == false || $state_val -le 0 ) ]]; then
                return
            fi
        fi
    done

    echo "$line\n"
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
