#!/bin/zsh

file="$HOME/.dotfiles/tmp/map.json"
if [[ $1 == "-m" ]]; then
    file="/tmp/map.json"
    shift 1

    if [[ ! -f $file ]]; then
        echo '{}' > "$file"
    fi
fi

if [[ $1 == set || $1 == inc ]]; then
    lock_path="/tmp/map.lock"
    lock_wait_iterations=0
    lock_id=$("$MY_SCRIPTS/lang/shell/rand.sh" 99999)

    while [[ -f $lock_path && $lock_wait_iterations -le 30 ]]; do
        sleep 0.1
        lock_wait_iterations=$((lock_wait_iterations + 1))
    done

    echo "$lock_id" > "$lock_path"

    # Verify we actually own it (avoid race condition)
    if [[ "$(cat "$lock_path")" != "$lock_id" ]]; then
        echo "Failed to acquire lock after writing"
        exit 1
    fi
fi

result=$(python3 $HOME/.dotfiles/scripts/lang/python/map.py "$file" "$@" )
code=$?

if [[ $1 == set || $1 == inc ]]; then

    # only remove if we own the lock
    if [[ -f $lock_path && "$(cat "$lock_path")" == "$lock_id" ]]; then
        rm -f "$lock_path"
    fi
fi

if [[ -n $result ]]; then
    echo "$result" | rat.sh -pPl "json"
fi

exit $code