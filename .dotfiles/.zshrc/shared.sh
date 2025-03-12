#!/bin/zsh

# ------------------------- VARIABLES ------------------------ #
export GPG_TTY=$(tty)
export PATH="$HOME/.dotfiles/scripts/path:$(printf "%s:" "$HOME/.dotfiles/scripts/path"/*/):$PATH"

export DOC="$HOME/Documents"
export DEV="$HOME/Developer"
export VAULT="$HOME/vault"
export MY_SCRIPTS="$HOME/.dotfiles/scripts"

# NOTE - Items must end with a comma, even last one
# NOTE - Used by todoist-app
export DISABLED_TD_APP_ITEMS="---,ob,"

# ---------------------------- ZSH STYLE --------------------------- #

ZSH_HIGHLIGHT_HIGHLIGHTERS+=(regexp main)

setopt RE_MATCH_PCRE
typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=(
    '\$[a-zA-Z0-9_][a-zA-Z0-9_]*' fg=cyan
    '[ \t]-*[0-9]+(\.[0-9]+)*(?=([ \t]|$|\)))' fg=blue
)

# ------------------------- UNCATEGORISED ALIASES ------------------------ #

alias c="qalc"
alias lines="grep -v '^$' | wc -l"
alias weather="curl -s 'wttr.in?2AMn'"

alias rand="$MY_SCRIPTS/lang/shell/rand.sh"

alias st="python3 $MY_SCRIPTS/lang/python/st.py"

# ------------------ UNCATEGORISED FUNCTIONS ----------------- #

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

function later { python3 $HOME/.dotfiles/scripts/lang/python/later.py "$@"; }
function _later_completions {
    _arguments '*:command:_command_names'
}
compdef _later_completions later

function ob { ob.sh $*; }
function _ob_completions {
    _files -W $VAULT
    _files -W $VAULT/i
    _files -W $VAULT/p
    _files -W $VAULT/tmp
}
compdef _ob_completions ob

function cht {
    if $MY_SCRIPTS/lang/shell/is_help.sh $*; then
        echo "cht <language> <query>" \
            "\n query is separated by +"
        return 0
    fi

    if [ -z "$1" ]; then
        echo "No language specified"
        return 1
    fi

    if [ -z "$2" ]; then
        echo "No query specified"
        return 1
    fi

    curl "cht.sh/$1/$2"
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

function clr {
    local cols=$(tput cols)
    for ((i = 0; i < $cols; i++)); do
        echo -n "="
    done

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

function gclone { git clone "git@github.com:helagro/$1.git" $DEV/$1; }
function gi { curl -s https://www.toptal.com/developers/gitignore/api/$@; }
function yq { yadm add -u && yadm commit -m "$*" && yadm push; }

# Git Quick Local
function gql {
    local commit_message="$*"
    if [ -z "$commit_message" ]; then
        local commit_message="Unspecified"
    fi

    git add .
    git commit -m "$commit_message"
}

# Git Quick
function gq {
    gql "$*"
    git push
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

function in_days {
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

function hm { python3 $MY_SCRIPTS/lang/python/hm.py "$@" | rat.sh -pPl 'json'; }
function group { python3 $MY_SCRIPTS/lang/python/group.py "$@" | rat.sh -pPl 'json'; }
function csv { conda run -n main python3 "$MY_SCRIPTS/lang/python/jsons_to_csv.py" $@ | rat.sh -pPl 'tsv'; }

function plot {
    if [[ -p /dev/stdin ]]; then
        local input=$(cat)
        nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$input" "$1" &
        # conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$input" "$1"
    else
        nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$*" "$1" &
    fi
}

function to_days {
    cat | jq -r 'to_entries | map("\(.key) \(.value)") | .[]' | while read the_date value; do
        weekday=$(date -j -f "%Y-%m-%d" $the_date +"%a")
        echo "{\"$weekday\": $value}"
    done | jq -s 'add' | rat.sh -pl json
}

function sens {
    local do_new_line=true

    if [[ "$1" == '-n' ]]; then
        do_new_line=false
        shift
    fi

    local result=$(curl -sS --connect-timeout 2 "192.168.3.46:8004/$1")

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

# -------------------------- TODOIST ------------------------- #

alias td="todoist"
alias tdl="$MY_SCRIPTS/lang/shell/tdl.sh"
alias tdi="tdl '(tod|od|p1)'"
alias tundo="tdls :inbox | tac | in.sh "

alias tdis='td s && tdi'
alias tdls='td s && tdl'

function tdcp {
    if [ -n "$1" ]; then
        last_todoist_project="$1"
    fi

    if [ "$2" = "s" ]; then
        td s
    fi

    local id_list=($(tdl "$last_todoist_project" | peco | awk '{print $1}' ORS=' ' | sed 's/\x1b\[[0-9;]*m//g'))
    tdc "${id_list[@]}"
    echo "${id_list[@]}"
}

function tdup {
    # ARGS: update, project?, s?

    if [ -n "$2" ]; then
        last_todoist_project="$2"
    fi

    if [ "$3" = "s" ]; then
        td s
    fi

    local id_list=($(tdl "$last_todoist_project" | peco | awk '{print $1}' ORS=' ' | sed 's/\x1b\[[0-9;]*m//g'))
    tdu "$last_todoist_project $1" "${id_list[@]}"
    echo "${id_list[@]}"
}

function tdu {
    if $MY_SCRIPTS/lang/shell/is_help.sh $*; then
        echo "tdu <update> <id>..."
        return 0
    fi

    local update=$1
    shift

    for id in "$@"; do
        local content_line=$(td show $id | grep Content | cut -d' ' -f2-)

        a "$content_line" "$update"
        tdc $id
    done
}

function tdc {
    for arg in "$@"; do
        (nohup todoist c "$arg" >/dev/null 2>&1 &)
    done
}

function a {
    if [ -z "$*" ]; then  # If no arguments passed
        if [ -t 0 ]; then # If terminal
            a_ui
        else # If piped
            # Read lines from pipe
            while read -r line; do
                line=$(echo "$line" | sed -e 's/^- \[ \] //' -e 's/^- //') # Remove checkboxes
                a "$line"
            done
        fi
    else # If arguments passed
        (
            (
                if command -v a.sh >/dev/null 2>&1; then
                    nohup a.sh "$*" >>$HOME/.dotfiles/logs/a.log 2>&1
                else
                    echo "FAILED TO ADD: '$*' - a.sh not found"
                fi
            ) &
        )
    fi
}

# ------------------------- OBSIDIAN ------------------------- #

function do_now {
    local do_write=false
    if [[ "$1" == "-w" ]]; then
        do_write=true
        shift
    fi

    local file_name="$VAULT/$*.md"

    if [[ ! -e "$file_name" ]]; then
        echo "$file_name does not exist"
        return 1
    fi

    local content=$(cat "$file_name")
    if echo $content | awk '/---/ {found = NR; next} NR > found' | a; then
        if $do_write; then
            echo $content | awk '/---/ {found = 1; next} found' >"$file_name"
            echo "---" >>"$file_name"
        fi
    fi
}

function randote {
    local file=$(find "$VAULT/i" -type f | sort -R | head -n 1)
    rat.sh -P "$file"

    a ob
}
