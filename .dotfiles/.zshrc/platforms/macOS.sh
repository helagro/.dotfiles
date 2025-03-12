#!/bin/zsh

# ------------------------- OTHER ------------------------ #

export PATH="/Users/h/Library/Python/3.9/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=$PATH:$HOME/go/bin

if command -v rbenv &>/dev/null; then
    eval "$(rbenv init -)"
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
    tdls @lect

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

    if rand 4 >/dev/null; then
        local table=$(curl -s --connect-timeout 2 "$MY_CONFIG_URL/online-tools/act.tsv")

        if [ -n "$table" ]; then
            echo "$table" >$local_online_tools/data/act.tsv
            print -u2 "Successfully updated act.tsv"
        else
            print -u2 "Failed to update act.tsv"
        fi
    fi

    local output=$(
        cd $local_online_tools/dist/act
        NODE_NO_WARNINGS=1 node index.js "$query"
    )

    # filters ---------------------------------------------------- #

    print -n -u2 "\033[90mExcluding: "

    if [ $(tdl :inbox | wc -l) -le 8 ]; then
        output=$(echo "$output" | grep -v '"inbox^"')
        print -n -u2 "inbox, "
    fi

    if [ $(ob b | wc -l) -le 4 ]; then
        output=$(echo "$output" | grep -v '"b^"')
        print -n -u2 "b, "
    fi

    print -u2 "\033[0m"

    # print ------------------------------------------------------ #

    echo $output | rat.sh -pPl "json" | act_highlight
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
    local do_silent=false

    if [[ $* == *"-s"* ]]; then
        do_silent=true
        shift
    fi

    output=$(
        echo "$2" | shortcuts run "$1" --output-type public.plain-text | cat
        echo
    )

    if ! $do_silent; then
        echo $output
    fi

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
    short day "$1" | to_color.sh blue
    echo

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
