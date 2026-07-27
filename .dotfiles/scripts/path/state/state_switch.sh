#!/bin/zsh

# NOTE!! - Doesn't work for states not currently in map

state_json=$(jq -n --argjson s "$(map.sh s)" --argjson ps "$(map.sh ps)" '$s * $ps')

state_keys=($(echo $state_json | jq -r 'keys[]'))

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
    [[ $1 == true || $1 != <-> || $1 -ge 1 ]]
}

# ==================================== EXECUTION =================================== #

length_matches=""

if [[ -n $1 ]]; then
    note_length=$(ob.sh "$1" | wc -l)
fi

while IFS= read -r line; do
    if [[ -n $1 && $line =~ '.*-IF.* <([0-9]+).*' ]]; then
        local number="$match[1]"
        if [ $note_length -le $number ]; then
            length_matches+="$line\n"
        fi
    else
        length_matches+="$line\n"
    fi
done

non_state_matches=""

echo "$length_matches" | while IFS= read -r line; do
    if [[ "$line" == *'**-IF'* ]]; then
        match_and "$line"

    elif [[ "$line" == *'*-IF'* ]]; then
        match_or "$line"
        
    elif [ -n "$line" ] && [[ "$line" != "---" ]]; then
        non_state_matches+="$line\n"
    fi
done

echo -n $non_state_matches | awk '!seen[$0]++' | sed 's/- \[ \] //g'
