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
alias lect="short lect && open 'obsidian://vault/vault/_/lect.md'"

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
    fi

    # Turn off focus?
    if $do_focus; then
        short focus off
    fi
}

# -------------------------- ROUTINE ------------------------- #

function dawn {
    wifi on

    local focus_mode="off"
    local theme=0
    local night_shift=0

    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)
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

    # Set env
    short focus "$focus_mode"
    short night_shift "$night_shift"
    short focus
    theme $theme

    sleep 2

    # States
    a "dawn #u"
    ob stateAdder | state_switch.sh | a
    ob stateDo | state_switch.sh | later "stdin"

    local sleep_amt=$(is sleep 1 | jq '.[]')
    if [ -n "$sleep_amt" ] && [ "$sleep_amt" != "null" ] && [ "$sleep_amt" -lt "$sleep_goal" ]; then
        a "@rm !(13:30) caffeine?"
        a "laundry? #b"
        a "go out? #b"
        a "make shake? #b"
    fi

    local yd_water=$(is water 1 1 | jq '.[]')
    if [[ $yd_water -le 900 ]]; then
        later "#water_yd: $yd_water -> hydrate"
    fi

    if [[ $(date +"%m") -le 2 ]]; then
        later "#plan sunlight exposure"
        a "winter 1 s #u"
    fi

    later

    echo

    # Display main stuff
    day tod
    ob dawn

    # Display secondary stuff
    tl.sh streaks
    for state in "${state_list[@]}"; do
        $(eval echo \$$state) && echo $state
    done
    ob rule
    ob p
}

function dinner {
    local temp=$(sens -n temp)
    if [[ $temp -gt $dinner_temp_threshold ]]; then
        echo "Turn off radiator - $temp°C > $dinner_temp_threshold°C )"
    fi

    # Track time
    local time_diff=$(bed_minus_dinner)
    [ -n "$time_diff" ] && a "bed_minus_dinner $time_diff s #u" && echo "tracked bed_minus_dinner AS $time_diff"

}

function eve {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    if $MY_SCRIPTS/lang/shell/is_help.sh $*; then
        print 'Usage: eve [options...]'
        printf " %-3s %-20s %s\n" "-l," "" "Skip enabling flight mode on phone"
        printf " %-3s %-20s %s\n" "-E," "" "Skip environment setup"
        printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
        return 0
    fi
    # Track routine
    a "eve #u"

    # Reset
    echo "" >$VAULT/p/rule.md
    echo "" >$VAULT/p/p.md

    # Tasks
    day tom
    echo

    # Show stats
    printf "podd: \e[33m%b\e[0m\n" "$(is -v podd 1)"
    printf "tv_min: \e[33m%b\e[0m\n" "$(is -v tv_min 1)"
    printf "tv_opens: \e[33m%b\e[0m\n" "$(is -v tv_opens 1)"

    # Track other stats
    a "p_ett $(tdis | lines | tr -d '[:space:]') s #u"
    local sleep_delay=$(fall_asleep_delay)
    if [ -n "$sleep_delay" ]; then
        a "$(in_days -1) sleep_delay $sleep_delay s #u"
    fi

    echo

    # Show other info
    forecast=$(weather)
    if [ -n "$forecast" ] | grep -q "snow"; then
        echo "$forecast"
    fi
    tl.sh hb
    echo -n temp:
    sens temp

    echo

    # Show note
    ob eve

    # State conditionals
    $has_fog && echo "fog -> ( walk, meditate )"

    echo

    # Setup environment
    if [[ ! " $@ " == *" -E "* ]]; then
        short focus sleep
        short night_shift 1
        theme 1
    fi

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

}

function bedtime {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

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
    ob zink
}
