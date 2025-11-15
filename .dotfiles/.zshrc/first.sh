#!/bin/zsh

export MY_SCRIPTS="$HOME/.dotfiles/scripts"
export LOCAL_SERVER_IP="192.168.3.46"

# -------------------------- ALIASES ------------------------- #

alias is_dark='[[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]'
alias gpt4="aichat -s -m openai:gpt-4o"
alias rand="$MY_SCRIPTS/lang/shell/rand.sh"

# ---------------------------- ZSH --------------------------- #

autoload -Uz compinit
compinit

setopt HIST_IGNORE_ALL_DUPS # Remove old duplicate commands from history
setopt HIST_IGNORE_DUPS     # Remove new duplicate commands from history
setopt HIST_IGNORE_SPACE    # Remove commands starting with space from history, useful for secrets

zstyle ':omz:update' mode auto

HISTSIZE=100000
SAVEHIST=20000

# --------------------------- MAIN --------------------------- #

function day {
    if [[ -z "$1" ]]; then
        date +'%Y-%m-%d'
        return
    fi

    if [[ "$1" == *-* ]]; then
        date -v"$1"d +"%Y-%m-%d"
    else
        date -v+"$1"d +"%Y-%m-%d"
    fi
}

function red_mode {
    if [[ $1 == '1' ]]; then
        print -n "\033]10;rgb:ff/df/df\007"
        short -s filter 1

        ZSH_HIGHLIGHT_REGEXP=()
    else
        print -n "\033]110\007"
        [[ -z $2 || $2 != 0 ]] && short -s filter 0

        ZSH_HIGHLIGHT_REGEXP=(
            '\$[a-zA-Z0-9_][a-zA-Z0-9_]*' fg=cyan
            '[ \t]-*[0-9]+(\.[0-9]+)*(?=([ \t]|$|\)))' fg=blue
        )
    fi
}