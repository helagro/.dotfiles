#!/bin/zsh

alias re_loc="git pull --rebase && clean && python src"
alias do_loc="cd $HOME/Developer/local-app && source .venv/bin/activate && python src"
alias do_glo="cd $HOME/server-app && docker stack rm my_stack && clean && docker stack deploy -c docker-compose.yml my_stack"

function clean {
    docker system prune -a
}

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
