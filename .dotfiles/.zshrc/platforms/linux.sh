#!/bin/zsh

alias do_loc="cd $HOME/Developer/local-app && source .venv/bin/activate"

function shout {
    if [ -n "$1" ]; then
        content="$1"
    else
        content=$(cat)
    fi

    if sudo -v &>/dev/null; then
        echo -n $content | sudo wall -n
    else
        echo -n $content | wall
    fi

}
