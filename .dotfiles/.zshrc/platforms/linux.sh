#!/bin/zsh

alias vsrc="source $HOME/Developer/env-tracker/.venv/bin/activate"

function shout {
    if [ -n "$1" ]; then
        content="$1"
    else
        content=$(cat)
    fi

    echo -n $content | sudo wall -n
}
