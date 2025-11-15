#!/bin/zsh

# ------------------------- VARIABLES ------------------------ #
export GPG_TTY=$(tty)
export FZF_DEFAULT_OPTS="--ansi --no-sort --layout=reverse-list"

export DOC="$HOME/Documents"
export DEV="$HOME/Developer"
export VAULT="$HOME/vault"

# ---------------------------- ZSH SETTINGS --------------------------- #

setopt autopushd
setopt extended_glob
export LANG=en_US.UTF-8

ZSH_HIGHLIGHT_HIGHLIGHTERS+=(regexp main)

setopt RE_MATCH_PCRE
typeset -A ZSH_HIGHLIGHT_REGEXP

# ------------------------- UNCATEGORISED ALIASES ------------------------ #

alias c="qalc"
alias st="python3 $MY_SCRIPTS/lang/python/st.py"
alias lines="grep -v '^$' | wc -l | tr -d '[:space:]' && echo"
alias fun="functions"

# ------------------ UNCATEGORISED FUNCTIONS ----------------- #

function ask {
    echo -n "$1 (y/n) "
    read response
    [[ "$response" =~ ^[Yy]$ ]]
}

function clr {
    local cols=$(tput cols)
    printf '%*s' $cols | tr ' ' '='

    echo "\n"
    clear
}

# Counter function, used by other things
function cnt {
    if [[ -e "$HOME/.dotfiles/tmp/cnt.txt" ]]; then
        local cnt=$(cat "$HOME/.dotfiles/tmp/cnt.txt")
    else
        local cnt=0
    fi

    echo $cnt
    echo -n $((cnt + 1)) >"$HOME/.dotfiles/tmp/cnt.txt"
}

function pass {
    local do_copy=false

    if [[ $1 == "-c" ]]; then
        do_copy=true
        shift
    fi

    local passw=$(op item get "$@" --reveal --fields password)
    echo $passw

    if $do_copy; then
        echo $passw | pbcopy
    fi
}

function tab {
    cd "$HOME/.dotfiles/config/tabs/$1"
    exec zsh
}

function talk {
    if [[ "$*" == *"-s"* ]]; then
        local folder="$HOME/Library/Mobile Documents/com~apple~CloudDocs/media"
    else
        local folder="$HOME/Desktop"
    fi

    local text
    read -r -d '' text

    # process text ----------------------------------------------- #

    text=$(
        echo "$text" |
            sed -E 's/\[([0-9]| e|,)+\]//g' |
            sed -E 's/\([0-9]+\)//g' |
            tr -s '[:space:]' |
            sed -E 's/\(s\)/s/g' |
            sed 's/[^[:alnum:][:punct:][:space:]]//g'
    )

    # prepare running -------------------------------------------- #

    if [[ "$*" == *"-R"* ]]; then
        echo "$text"
        return 0
    fi

    local chunk_size=4000
    local text_length=${#text}
    local start=1
    local files=()
    local file_name=""

    # record in chunks ------------------------------------------- #

    while ((start <= text_length)); do
        local chunk="${text[start - 1, start + chunk_size - 2]}"

        file_name="$folder/tmp_$(cnt | tr -d '[:space:]').mp3"
        echo "$chunk" | gosling - $file_name -r 1.2
        files+=("$file_name")
        ((start += chunk_size))
        sleep 0.5
    done

    # combine chunks --------------------------------------------- #

    file_name="$folder/$(cnt | tr -d '[:space:]').mp3"
    cat "${files[@]}" >"$file_name"
    open $file_name
    rm "${files[@]}"
}

function weather {
    local layout="2"

    if [[ "$1" == "-l" ]]; then
        layout="$2"
        shift 2
    fi

    curl -s --max-time 4 "wttr.in?${layout}AMnQ"
}

function yadm_enc {
    echo -n "" | pbcopy

    if ! pass -c yadm >/dev/null 2>&1; then
        return 1
    fi

    if [[ $(pbpaste | wc -c) -lt 16 ]]; then
        echo "Password too short"
        return 1
    fi

    yadm encrypt

    echo -n "" | pbcopy
}


# ---------------------------- GIT --------------------------- #

alias gaa="git add ."      # Git Add All
alias gcm="git commit -m " # Git Commit Message
alias gsw="git switch "    # Git Switch

function gclone { git clone "git@github.com:helagro/$1.git" $DEV/$1; }      # Git Clone
function gi { curl -s https://www.toptal.com/developers/gitignore/api/$@; } # Git Ignore
function yq { yadm add -u && yadm commit -m "$*" && yadm push; }            # Yadm Quick
function gq { gql "$*" && git push; }                                       # Git Quick
function gqa { gaa && git commit --amend && git push -f; }                  # Git Quick Amend

# Git Quick Local
function gql {
    local commit_message="$*"
    if [ -z "$commit_message" ]; then
        local commit_message="Unspecified"
    fi

    git add .
    git commit -m "$commit_message"
}

# Git Delete Branch
function gdb {
    git branch -d "$1"
    git push origin --delete "$1"
}

function repo {
    local url=$(git config --get remote.origin.url)
    local url=$(echo $url | sed 's/git@github.com:/https:\/\/github.com\//g')
    open $url
}

# later ---------------------------------------------------------------------- #

function later { python3 $HOME/.dotfiles/scripts/lang/python/later.py "$@"; }
function _later_completions {
    _arguments '*:command:_command_names'
}
compdef _later_completions later

function latera { later "a \"$*\""; }
function latero {
    local url="$*"
    if [[ $url != http* ]]; then
        url="https://$url"
    fi

    later "open \"$url\""
}

# --------------------------- DATES -------------------------- #

function year_day {
    local this_year_day=$(date +%j)

    if [ -z "$1" ]; then
        echo $this_year_day
    else
        echo $((this_year_day + $1 * 365))
    fi

}
