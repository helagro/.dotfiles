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
alias wifi="networksetup -setairportpower en0" # ARG - on/off
alias oblank="open 'obsidian://vault/vault/_/blank.md'"

alias tg="toggl"
alias tgc="toggl current | grep -vE 'Workspace|ID'"

# ------------------------- OTHER FUNCTIONS ------------------------ #

function reinstall {
    cd "$MY_SCRIPTS/lang/shell" && ./list_app.sh
    ob reinstall
}

function breake {
    local config_path=$(look_away --config-path)
    if [ -z "$config_path" ]; then
        config_path="$HOME/Library/Application Support/look_away/config.yaml"
    fi

    nvim "$config_path"
}

function test {
    local output=$(act b)
}

function lect {
    short lect

    ob lect
    tdls @lect

    tgs study
    a "social 1 s #u"
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

alias home="short -s home"

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

function info {
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
    local skip_tgs=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --focus)
            do_focus=true
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
            printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
            return 0
            ;;
        -T | --skip-tgs)
            skip_tgs=true
            shift
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

    ping -c1 -t1 8.8.8.8 &>/dev/null && local offline=false || local offline=true

    # If exor type activity
    if ! $offline && ! $skip_tgs && [[ $2 == "medd" || $2 == "yoga" || $2 == "mindwork" ]]; then
        tgs exor "$2"
    fi

    local start_time=$(date +%s)

    # Run stopwatch
    if $do_silent; then
        command -v 'caffeinate' >/dev/null && caffeinate -disu -i $DOC/stopwatch/main "$1" 1>&2
    else
        command -v 'caffeinate' >/dev/null && caffeinate -disu -i $DOC/stopwatch/main "$1"

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
            if $offline; then
                local track_cmd="$(day) $2 $min #u"
            else
                local track_cmd="$2 $min #u"
            fi

            echo "$track_cmd" | to_color.sh yellow
            a "$track_cmd"
        fi

    fi
    
    if ! $offline && ! $skip_tgs; then
        tg stop
    fi

    if $do_focus; then
        short focus off
    fi
}
