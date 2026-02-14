#!/bin/zsh

file="$HOME/.dotfiles/tmp/map.json"
if [[ $1 == "-m" ]]; then
    file="/tmp/map.json"
    shift 1

    if [[ ! -f $file ]]; then
        echo '{}' > "$file"
    fi
fi

result=$(python3 $HOME/.dotfiles/scripts/lang/python/map.py "$file" "$@" )
code=$?

if [[ -n $result ]]; then
    echo "$result" | rat.sh -pPl "json"
fi

exit $code