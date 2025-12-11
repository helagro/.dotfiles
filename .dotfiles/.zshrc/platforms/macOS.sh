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

function beep {
    local vol=0.7
    [ -n "$1" ] && vol=$1

    (sox -v $vol '/System/Library/Sounds/Purr.aiff' -d >/dev/null 2>&1 & )
}

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

function is_home {
    if ping -c1 -t1 8.8.8.8 &>/dev/null; then
        ping -c1 -t1 "$LOCAL_SERVER_IP" &>/dev/null
        if [ $? -eq 0 ]; then
            loc sens temp &>/dev/null
            return $?
        else
            return 1
        fi
    else
        return 1
    fi
}

function test {
    local output=$(act b)
}

function lect {
    [[ $* != *'-T'* ]] && theme 0
    [[ $* != *'-M'* ]] && osascript -e 'set volume with output muted'
    ( python3 "$MY_SCRIPTS/lang/python/a.py" map set -k extra_features_delay -v "7" & )

    # Misc
    a 'plan return #b'
    open 'obsidian://open?file=p%2Flect'
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

    if $is_red_tab; then
        printf "\033]10;rgb:ff/30/30\007"
    fi
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
    local skip_newline=false
    local multiline_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -s | --silent)
            do_silent=true
            shift 1
            ;;
        -N | --no-newline)
            skip_newline=true
            shift 1
            ;;
        -m | --multiline-output)
            multiline_output=true
            shift 1
            ;;
        *)
            break
            ;;
        esac
    done

    output=$(
        if $skip_newline; then
            printf "$2" | shortcuts run "$1" --output-type public.plain-text
        else
            echo "$2" | shortcuts run "$1" --output-type public.plain-text
        fi
    )

    if ! $do_silent; then
        if $multiline_output; then
            echo "$output"
        else
            echo "$output" | tr -d '\n'
            echo
        fi
    fi

    if [[ $? -ne 0 ]]; then
        echo "Failure when running: $1 $2"
        return 1
    fi
}

function home {
    while [[ $# -gt 0 ]]; do
        (short -s home $1 &)
        shift
    done
}

function inv {
    if [[ $1 == "1" ]]; then
        1="on"
    fi

    short invert $1
}

function info {
    short -m -N day "$1" | to_color.sh blue
    echo

    tdis
}

# -------------------------- TIMING -------------------------- #

alias timer="short -s timer"

function sw {
    # Initialise variables
    local do_focus=false
    local just_output=false
    
    local time=""
    local trackable=false
    local activity=""
    local is_important=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --focus)
            do_focus=true
            shift
            ;;
        -j | --just-output)
            just_output=true
            shift
            ;;
        -i | --important)
            is_important=true
            shift
            ;;
        -a | --activity)
            activity=$2
            shift 2
            ;;
        *)
            break
            ;;
        esac
    done

    [[ -n $1 ]] && time=$1
    [[ $activity == "medd" || $activity == "yoga" || $activity == "mindwork" || $activity == "main" ]] && trackable=true


    # handle pre-timer setup ----------------------------------------------------- #

    if $do_focus; then
        short -s focus on
    fi

    if $trackable; then
        echo "[tracking]" | to_color.sh yellow   
    fi

    # run stopwatch -------------------------------------------------------------- #

    local start_time=$(date +%s)
    if $just_output; then
        command -v 'caffeinate' >/dev/null && caffeinate -disu -i $DOC/stopwatch/main $time 1>&2
    else
        command -v 'caffeinate' >/dev/null && caffeinate -disu -i $DOC/stopwatch/main $time
    fi

    # handle timer ending --------------------------------------------------- #

    if [[ $? -ne 2 ]] && ! $just_output; then
        if $is_important; then
            timer 0
        else
            asciiquarium
        fi
    fi

    # Calculate time
    local end_time=$(date +%s)
    local min=$((($end_time - $start_time) / 60))

    # handle result -------------------------------------------------------------- #

    if $just_output; then
        echo -n "$min"
    elif $trackable; then
        if [ "$min" -eq 0 ]; then
            echo "(Not tracking because time was less than 1 minute)"
        else
            # Track time
            if ping -c1 -t1 8.8.8.8 &>/dev/null; then
                local track_cmd="$activity $min #u"
            else
                local track_cmd="$(day) $activity $min #u"
            fi

            echo "$track_cmd" | to_color.sh yellow
            a "$track_cmd"
        fi

    fi

    # reset state ---------------------------------------------------------------- #

    if $do_focus; then
        short -s focus off
    fi
}
