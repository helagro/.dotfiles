#!/bin/zsh

export MY_SCRIPTS="$HOME/.dotfiles/scripts"
export LOCAL_SERVER_IP="192.168.3.46"

# -------------------------- ALIASES ------------------------- #

alias is_dark='[[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]'
alias gpt4="aichat -s -m openai:gpt-4o"
alias rand="$MY_SCRIPTS/lang/shell/rand.sh"

alias is_online="is_home || ping -c1 -t1 8.8.8.8 &>/dev/null"

# ---------------------------- ZSH --------------------------- #

autoload -Uz compinit
compinit

setopt HIST_IGNORE_ALL_DUPS # Remove old duplicate commands from history
setopt HIST_IGNORE_DUPS     # Remove new duplicate commands from history
setopt HIST_IGNORE_SPACE    # Remove commands starting with space from history, useful for secrets

zstyle ':omz:update' mode auto
zstyle ':omz:update' verbose no
zstyle ':omz:update' frequency 30
export DISABLE_UPDATE_PROMPT=true

HISTSIZE=100000
SAVEHIST=20000

# --------------------------- MAIN --------------------------- #

function loc {
    local do_new_line=true
    local do_silent=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -n | --no-new-line)
            do_new_line=false
            shift 1
            ;;
        -S | --not-silent)
            do_silent=false
            shift 1
            ;;
        -s | --silent)
            do_silent=true
            shift 1
            ;;
        *)
            break
            ;;
        esac
    done

    local params="${(j:/:)@}"
    local result=$(curl -sS --connect-timeout 2 "$LOCAL_SERVER_IP:8004/$params")

    if [[ $? -ne 0 ]]; then
        result='{"error": "Could not connect to local server"}'
        return 1
    fi

    if $do_silent || [[ $result == "ok" ]]; then
        return 0
    fi

    if $do_new_line; then
        echo "$result" | rat.sh -pPl "json"
    else
        echo -n "$result" | rat.sh -pPl "json"
    fi
}

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

function is_home {
    ping -c1 -t1 "$LOCAL_SERVER_IP" &>/dev/null
    if [ $? -eq 0 ]; then
        loc health &>/dev/null
        return $?
    else
        if [[ $1 == '--guess-yes' ]]; then
            return 0
        else
            return 1
        fi
    fi
}

function red_mode {
    if [[ $1 == '1' ]]; then
        printf "\033]10;rgb:ff/30/30\007"
        [[ -z $2 || $2 != 0 ]] && short -s filter 1

        ZSH_HIGHLIGHT_REGEXP=()
    else
        $is_red_tab || print -n "\033]110\007"
        [[ -z $2 || $2 != 0 ]] && short -s filter 0

        ZSH_HIGHLIGHT_REGEXP=(
            '\$[a-zA-Z0-9_][a-zA-Z0-9_]*' fg=cyan
            '[ \t]-*[0-9]+(\.[0-9]+)*(?=([ \t]|$|\)))' fg=blue
        )
    fi
}