#!/bin/zsh

value_only=false

if [[ "$1" == "-v" ]]; then
    value_only=true
    shift
fi

if [ $# -gt 0 ]; then
    # if conda installed
    if command -v conda &>/dev/null; then
        is_output=$(conda run -n main python3 "$HOME/.dotfiles/scripts/lang/python/exist.py" $@)
        code=$?
    else
        is_output=$(python3 "$HOME/.dotfiles/scripts/lang/python/exist.py" $@)
        code=$?
    fi
fi

if $value_only; then
    echo $is_output | jq '.[]' | rat.sh -pl 'json'
else
    echo $is_output | rat.sh -pl 'json'
fi

if [ -n "$code" ]; then
    exit $code
fi
