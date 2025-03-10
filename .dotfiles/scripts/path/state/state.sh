#!/bin/zsh

do_silent=false
if [[ "$1" == "-s" ]]; then
    do_silent=true
    shift 1
fi

json=$(cat $HOME/.dotfiles/tmp/state.json)
value=$(echo $json | jq ".$1")

if ! $do_silent; then
    echo $value
fi

if [[ -n "$1" ]]; then
    $value
fi
