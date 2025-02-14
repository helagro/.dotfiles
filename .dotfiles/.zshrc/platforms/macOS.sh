#!/bin/zsh

# ------------------------- OTHER ------------------------ #

export PATH="/Users/h/Library/Python/3.9/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=$PATH:$HOME/go/bin

if command -v rbenv &>/dev/null; then
    eval "$(rbenv init -)"
fi

# -------------------------- SOURCE -------------------------- #

if [[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# ----------------------- OTHER ALIASES ---------------------- #

alias vi="nvim"
alias archive="$HOME/Documents/archiver-go/build/macOS"
alias breake="nvim $DOC/break-timer/.env"
alias wifi="networksetup -setairportpower en0" # NOTE - on/off
alias tg="toggl"
alias tgc="toggl current | grep -vE 'Workspace|ID'"

alias oblank="open 'obsidian://vault/vault/p/lect.md'"

# ------------------------- OTHER FUNCTIONS ------------------------ #

function lect {
    short lect
    ob lect
    tgs study
}

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

function missing_sleep {
    [ -n "$1" ] && [ "$1" != "null" ] && [ "$1" -lt "$sleep_goal" ]
}

function act {
    local local_online_tools="$HOME/Documents/online-tools"
    local query=$(echo "$*" | tr ' ' '/')

    if rand 5 >/dev/null; then
        local table=$(curl -s --connect-timeout 2 "$MY_CONFIG_URL/online-tools/act.tsv")

        if [ -n "$table" ]; then
            echo "$table" >$local_online_tools/data/act.tsv
        fi
    fi

    (
        cd $local_online_tools/dist/act
        NODE_NO_WARNINGS=1 node index.js "$query" | bat -pPl "json"
    )
}

function theme {
    local new_mode=$1

    if [ -z "$new_mode" ]; then
        new_mode='not dark mode'
    fi

    osascript -e "
        tell application \"System Events\"
            tell appearance preferences
                set dark mode to $new_mode
            end tell
        end tell
    "
}

function on_tab {
    clr

    if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/a" ]]; then
        if [[ -z "$has_setup_highlight" ]]; then
            has_setup_highlight=1
            ZSH_HIGHLIGHT_REGEXP+=(
                '#[a-z0-9]+[a-zA-Z0-9]*' fg=green,bold
                '(\s|^)p3(\s|$)' fg=magenta,underline
                '(\s|^)p1(\s|$)' fg=red,bold
                '\*\*.+\*\*' fg=red,bold
                '(?<!\*)\*[^*]+\*(?!\*)' fg=magenta,underline
                ';' fg=yellow,bold
                '@\w+' fg=blue
                '\$\([^\$]+\)' fg=cyan
            )
        fi

        unset ZSH_AUTOSUGGEST_STRATEGY

        a
    fi
}

function pass {
    local passw=$(op item get "$@" --reveal --fields password)
    echo $passw
    echo $passw | pbcopy
}

function e {
    if [ -d "$DEV/$1" ]; then
        code "$DEV/$1"
    elif [ -d "$DOC/$1" ]; then
        code "$DOC/$1"
    elif [ -d "$1" ]; then
        code "$1"
    elif [ -e "$*" ]; then
        nvim "$*"
        return 0
    else
        gclone $1

        if [ $? -eq 0 ]; then
            code "$DEV/$1"
        else
            return 1
        fi
    fi

    if [ $# -ge 2 ]; then
        shift
        e $*
    fi
}

function e_completion {
    _files -W $DEV
    _files -W $DOC
}

compdef e_completion e

# ---------------------- APPLE SHORTCUTS --------------------- #

function short {
    echo "$2" | shortcuts run "$1"

    if [[ $? -ne 0 ]]; then
        echo "Failure when running: $1 $2"
        return 1
    fi
}

function inv {
    if [[ $1 == "1" ]]; then
        1="on"
    fi

    short invert $1
}

function day {
    local clipBoard=$(pbpaste)

    short day "$1"
    pbpaste

    echo && echo
    echo -n $clipBoard | pbcopy

    tdis
}

# -------------------------- TIMING -------------------------- #

alias timer="short timer"

function sw {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    # Initialise variables
    local time=-1
    local do_focus=false
    local do_silent=false
    local offline_mode=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --focus)
            do_focus=true
            shift
            ;;
        -o | --offline)
            offline_mode=true
            shift
            ;;
        -s | --silent)
            do_silent=true
            shift
            ;;
        -h | --help)
            print 'Usage: sw [options...] <duration> <activity>'
            printf " %-3s %-20s %s\n" "-f" "--focus" "Do set focus"
            printf " %-3s %-20s %s\n" "-s" "--silent" "Silent mode"
            printf " %-3s %-20s %s\n" "-o" "--offline" "Offline mode"
            printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
            return 0
            ;;
        *)
            break
            ;;
        esac
    done

    # Turn on focus?
    if $do_focus; then
        short focus on
    fi

    # If provided time
    if [ -n "$1" ]; then
        time=$1
    fi

    # If exor type activity
    if ! $offline_mode && [[ $2 == "medd" || $2 == "yoga" ]]; then
        tgs exor "$2"
    fi

    local start_time=$(date +%s)

    # Run stopwatch
    if $do_silent; then
        caffeinate -disu -i $DOC/stopwatch/main "$1" 1>&2
    else
        caffeinate -disu -i $DOC/stopwatch/main "$1"

        if [ $? -ne 2 ]; then
            asciiquarium
        fi
    fi

    # Calculate time
    local end_time=$(date +%s)
    local min=$((($end_time - $start_time) / 60))

    # Run execute output
    if $do_silent; then
        echo -n "$min"
    elif [ -n "$2" ]; then
        if [ "$min" -eq 0 ]; then
            echo "(Not tracking because time was less than 1 minute)"
        else
            if $offline_mode; then
                a "$(tod) $2 $min #u"
            else
                a "$2 $min #u"
            fi
        fi

        if ! $offline_mode; then
            tg stop
        fi
    fi

    # Turn off focus?
    if $do_focus; then
        short focus off
    fi
}
