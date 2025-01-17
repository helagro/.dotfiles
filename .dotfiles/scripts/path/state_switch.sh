#!/bin/zsh
source $HOME/.dotfiles/.zshrc/custom.sh

matches=""

while IFS= read -r line; do
    if [[ "$line" == *-IF* ]]; then
        for state in "${state_list[@]}"; do
            state_val=$(eval echo \$$state)

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
