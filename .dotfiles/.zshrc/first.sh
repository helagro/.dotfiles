#!/bin/zsh

export MY_SCRIPTS="$HOME/.dotfiles/scripts"

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

function tgs {
    local project=$1
    shift

    if [[ "$project" == "bodge" ]]; then
        toggl start -P 201773261 "$*"
    elif [[ "$project" == "study" ]]; then
        toggl start -P 181245378 "$*"
    elif [[ "$project" == "i" ]]; then
        toggl start -P 202093636 "$*"
    elif [[ "$project" == "p1" ]]; then
        toggl start -P 205212384 "$*"
    elif [[ "$project" == "exor" ]]; then
        toggl start -P 203446800 "$*"
    elif [[ "$project" == "none" ]]; then
        toggl start "$*"
    else
        return 1
    fi
}
