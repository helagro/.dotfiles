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
alias breake="nvim $doc/break-timer/.env"
alias wifi="networksetup -setairportpower en0" # NOTE - on/off
alias is_dark='[[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]'

# ------------------------- OTHER FUNCTIONS ------------------------ #

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
    local role=$(basename $(pwd))
    clr

    if [[ $role == "a" ]]; then
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

        a
    elif [[ $role == "ai" || $role == "ai_cheap" ]]; then
        if is_dark; then
            export AICHAT_LIGHT_THEME=0
        else
            export AICHAT_LIGHT_THEME=1
        fi

        [[ $role == "ai" ]] && gpt4
        [[ $role == "ai_cheap" ]] && gpt3
    fi

}

function pass {
    local passw=$(op item get "$@" --reveal --fields password)
    echo $passw
    echo $passw | pbcopy
}

function e {
    if [ -d "$dev/$1" ]; then
        code "$dev/$1"
    elif [ -d "$doc/$1" ]; then
        code "$doc/$1"
    elif [ -d "$1" ]; then
        code "$1"
    elif [ -e "$vault/$*.md" ]; then
        nvim "$vault/$*.md"
        return 0
    elif [ -e "$*" ]; then
        nvim "$*"
        return 0
    else
        gclone $1

        if [ $? -eq 0 ]; then
            code "$dev/$1"
        else
            return 1
        fi
    fi

    if [ $# -ge 2 ]; then
        shift
        e $*
    fi
}

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

# -------------------------- ROUTINE ------------------------- #

function dawn {
    wifi on

    local focus_mode="off"
    local theme=0
    local night_shift=0

    set -- $($my_scripts/lang/shell/expand_args.sh $*)
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --focus)
            focus_mode="$2"
            shift 2
            ;;
        -t | --theme)
            theme="$2"
            shift 2
            ;;
        -n | --night)
            night_shift=1
            shift
            ;;
        -h | --help)
            echo "Usage: dawn [-f <focus_mode>] [-t <theme>] -n (night shift)"
            return 0
            ;;
        *)
            echo "Unknown option: $1"
            return 1
            ;;
        esac
    done

    sleep 2

    short focus "$focus_mode"
    short night_shift "$night_shift"
    short focus
    theme $theme

    day tod
    ob dawn

    tl streaks
    ob rule
    ob p

    a "dawn #u"

    later
}

function eve {
    if $my_scripts/lang/shell/is_help.sh $*; then
        print 'Usage: eve [options...]'
        printf " %-3s %-20s %s\n" "-l," "" "Skip enabling flight mode on phone"
        printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
        return 0
    fi

    # Reset
    echo "" >$vault/p/rule.md
    echo "" >$vault/p/p.md

    # Tasks
    day tom
    echo

    # Show stats
    echo -n temp:
    sens temp
    echo "podd:"
    is podd 1
    echo "tv_min:"
    is tv_min 1

    # Show other info
    forecast=$(weather)
    if [ -n "$forecast" ] | grep -q "snow"; then
        echo "$forecast"
    fi
    tl hb

    # Show note
    echo
    ob eve

    # Setup environment
    short focus sleep
    short night_shift 1
    theme 1

    # Deletes tasks tagged @rm. NOTE - Has safeties and redundancies
    local del_tasks=$(tdls '@rm' -epF 'p1' | grep '@rm' | head -n 10)
    echo "$del_tasks" >>$HOME/.dotfiles/logs/eve.log
    local del_ids=$(echo -n "$del_tasks" | grep -o '^[0-9]*' | tr -s '[:space:]' ' ')
    if tdc $del_ids; then
        echo "Auto-deleted $(echo -n "$del_ids" | wc -w | tr -d '[:space:]') task(s)"
    else
        echo 'Auto task deletion failed'
    fi

    # Phone
    if [[ ! " $@ " == *" -l "* ]]; then
        sleep 9
        short phondo "flight mode"
    fi

    # Track
    a "eve #u"
    a "p_ett $(tdis | lines | tr -d '[:space:]') s #u"
    local sleep_delay=$(fall_asleep_delay)
    if [ -n "$sleep_delay" ]; then
        a "$(in_days -1) sleep_delay $sleep_delay s #u"
    fi
}

function bedtime {
    set -- $($my_scripts/lang/shell/expand_args.sh $*)

    local do_phone=1
    local wifi=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -p)
            do_phone="$2"
            shift 2
            ;;
        -w)
            wifi="$2"
            shift 2
            ;;
        -h | --help)
            print 'Usage: bedtime [options...]'
            printf " %-3s %-20s %s\n" "-p" "<1/0>" "Do set phone settings"
            printf " %-3s %-20s %s\n" "-w" "<1/0>" "Wifi on/off"
            printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
            return 0
            ;;
        *)
            echo "Unknown option: $1"
            return 1
            ;;
        esac
    done

    sens temp

    if [[ $do_phone -eq 1 ]]; then
        short phondo "flight mode"
    fi

    if [[ $wifi -eq 1 ]]; then
        wifi on
    else
        sleep 2
        wifi off
    fi

    short focus sleep
    ob bedtime
}

# -------------------------- TIMING -------------------------- #

alias timer="short timer"

function medd {
    set -- $($my_scripts/lang/shell/expand_args.sh $*)

    local do_focus=false
    local time=-1

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --focus)
            do_focus=true
            shift
            ;;
        -h | --help)
            print 'Usage: medd [options...] <duration>'
            printf " %-3s %-20s %s\n" "-f" "" "Do set focus"
            printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
            return 0
            ;;
        *)
            time=$1
            shift
            ;;
        esac
    done

    if $do_focus; then
        short focus on
    fi

    sw $time "medd"

    if $do_focus; then
        short focus off
    fi
}

function sw {
    if $my_scripts/lang/shell/is_help.sh $*; then
        echo "Usage: sw <duration> [ <activity> | -s ]"
        return 0
    fi

    local start_time=$(date +%s)

    if [[ $2 == "-s" ]]; then
        caffeinate -disu -i $doc/stopwatch/main "$1" 1>&2
    else
        caffeinate -disu -i $doc/stopwatch/main "$1"

        if [ $? -ne 2 ]; then
            asciiquarium
        fi
    fi

    local end_time=$(date +%s)
    local min=$((($end_time - $start_time) / 60))

    if [[ "$2" == "-s" ]]; then
        echo -n "$min"
    elif [ -n "$2" ] && [ "$min" -ne 0 ]; then
        a "$2 $min #u"
    fi
}
