#!/bin/zsh

# ------------------------- VARIABLES ------------------------ #
export GPG_TTY=$(tty)
export FZF_DEFAULT_OPTS="--ansi --no-sort --layout=reverse-list"

export DOC="$HOME/Documents"
export DEV="$HOME/Developer"
export VAULT="$HOME/vault"

export LOCAL_SERVER_IP="192.168.3.46"
# NOTE - Items must end with a comma, even last one
# NOTE - Used by server-app
export DISABLED_TD_APP_ITEMS="---,ob,null,"

# ---------------------------- ZSH SETTINGS --------------------------- #

setopt autopushd
setopt extended_glob
export LANG=en_US.UTF-8

ZSH_HIGHLIGHT_HIGHLIGHTERS+=(regexp main)

setopt RE_MATCH_PCRE
typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=(
    '\$[a-zA-Z0-9_][a-zA-Z0-9_]*' fg=cyan
    '[ \t]-*[0-9]+(\.[0-9]+)*(?=([ \t]|$|\)))' fg=blue
)

# ------------------------- UNCATEGORISED ALIASES ------------------------ #

alias c="qalc"
alias st="python3 $MY_SCRIPTS/lang/python/st.py"

alias lines="grep -v '^$' | wc -l | tr -d '[:space:]'"
alias len_tod='grep -F $(day) | lines'

# ------------------ UNCATEGORISED FUNCTIONS ----------------- #

function ect {
    pushd $DEV/config > /dev/null
    vd public/server-app/act.tsv
    ask "Deploy to Firebase?" && firebase deploy
    popd > /dev/null
}

function tab {
    cd "$HOME/.dotfiles/config/tabs/$1"
    exec zsh
}

function addo {
    pushd $VAULT > /dev/null
    git add "$1.md"
    popd > /dev/null
}

function ask {
    echo -n "$1 (y/n) "
    read response
    [[ "$response" =~ ^[Yy]$ ]]
}

function weather {
    local layout="2"

    if [[ "$1" == "-l" ]]; then
        layout="$2"
        shift 2
    fi

    curl -s --max-time 4 "wttr.in?${layout}AMnQ"
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


function obc {
    local file="$1"
    shift
    local lang="markdown"

    if [[ "$*" == *"-l"* ]]; then
        lang="json"
    fi

    ob "$file" | python3 $MY_SCRIPTS/lang/python/ob_filter.py "$@" | rat.sh -Pl "$lang" --file-name "$file"
}

function ob {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    ob.sh $*
}
function _ob_completions {
    _files -W $VAULT
    _files -W $VAULT/i
    _files -W $VAULT/p
    _files -W $VAULT/tmp
}
compdef _ob_completions ob

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

# --------------------------- DATES -------------------------- #

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

function year_day {
    local this_year_day=$(date +%j)

    if [ -z "$1" ]; then
        echo $this_year_day
    else
        echo $((this_year_day + $1 * 365))
    fi

}

# ------------------------- TRACKING ------------------------- #

alias sens="loc"

function hm { python3 $MY_SCRIPTS/lang/python/hm.py "$@" | rat.sh -pPl 'json'; }
function group { python3 $MY_SCRIPTS/lang/python/group.py "$@" | rat.sh -pPl 'json'; }
function csv { conda run -n main python3 "$MY_SCRIPTS/lang/python/jsons_to_csv.py" $@ | rat.sh -pPl 'tsv'; }

function plot {
    if [[ -p /dev/stdin ]]; then
        local input=$(cat)
        (nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$input" "$1" >/dev/null &)
        # conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$input" "$1"
    else
        (nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$*" "$1" >/dev/null &)
    fi
}

function to_days {
    cat | jq -r 'to_entries | map("\(.key) \(.value)") | .[]' | while read the_date value; do
        weekday=$(date -j -f "%Y-%m-%d" $the_date +"%a")
        echo "{\"$weekday\": $value}"
    done | jq -s 'add' | rat.sh -pl json
}

function loc {
    local do_new_line=true

    if [[ "$1" == '-n' ]]; then
        do_new_line=false
        shift
    fi

    local result=$(curl -sS --connect-timeout 2 "$LOCAL_SERVER_IP:8004/$1")

    if $do_new_line; then
        echo "$result" | rat.sh -pPl "json"
    else
        echo -n "$result" | rat.sh -pPl "json"
    fi
}

function is {
    local value_only=false

    if [[ "$1" == "-v" ]]; then
        value_only=true
        shift
    fi

    if [ $# -gt 0 ]; then
        # if conda installed
        if command -v conda &>/dev/null; then
            is_output=$(conda run -n main python3 "$HOME/.dotfiles/scripts/lang/python/exist.py" $@)
            local code=$?
        else
            is_output=$(python3 "$HOME/.dotfiles/scripts/lang/python/exist.py" $@)
            local code=$?
        fi
    fi

    if $value_only; then
        echo $is_output | jq '.[]' | rat.sh -pl 'json'
    else
        echo $is_output | rat.sh -pl 'json'
    fi

    if [ -n "$code" ]; then
        return $code
    fi
}

# ------------------------- OBSIDIAN ------------------------- #

function do_now {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    local do_write=false
    local do_add=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help)
            echo "Usage: do_now [-w] <file_name>"
            echo "  -w: Overwrite the contents following '---'"
            return 0
            ;;
        -w | --write)
            do_write=true
            shift 1
            ;;
        -D | --do-not-add)
            do_add=false
            shift 1
            ;;
        *)
            local file_name="$VAULT/$1.md"
            shift
            ;;
        esac
    done

    if [[ ! -e "$file_name" ]]; then
        echo "$file_name does not exist"
        return 1
    fi

    local content=$(cat "$file_name")
    local tasks=$(echo $content | awk '/----/ {found = NR; next} NR > found')

    if [[ $? -eq 0 ]]; then
        if $do_add; then
            echo "$tasks" | a
        fi

        if $do_write; then
            echo "$content" | awk '/----/ {exit} {print}' >"$file_name"
            echo "----" >>"$file_name"
        fi
    else
        echo "Error reading file: $file_name"
        return 1
    fi
}
