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
alias wifi="networksetup -setairportpower en0" # NOTE - on/off
alias tg="toggl"
alias tgc="toggl current | grep -vE 'Workspace|ID'"

alias oblank="open 'obsidian://vault/vault/p/lect.md'"

# ------------------------- OTHER FUNCTIONS ------------------------ #

function breake {
    local break_path=$(look_away --config-path)
    nvim "$break_path"
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

    # general filters ---------------------------------------------------- #

    print -n -u2 "\033[90mExcluding: "

    if [ $(ob b | wc -l) -le 4 ]; then
        output=$(echo "$output" | grep -v 'b^')
        print -n -u2 "b, "
    fi

    if ! $has_flashcards; then
        output=$(echo "$output" | grep -v 'flashcards^')
        print -n -u2 "flashcards, "
    fi

    if [[ $(obsi.sh 8 | wc -l) -lt 3 ]]; then
        output=$(echo "$output" | grep -v 'obsi^')
        print -n -u2 "obsi, "
    fi

    # todoist filters ------------------------------------------------------------ #

    if [ $(tdl :inbox | wc -l) -le 8 ]; then
        output=$(echo "$output" | grep -v 'inbox^')
        print -n -u2 "inbox, "
    fi

    if [ $(tdl :u -F '#ludilo|#run' | wc -l) -le 10 ]; then
        output=$(echo "$output" | grep -v 'u^')
        print -n -u2 "u, "
    fi

    if [ $(tdl :u -F '#res' | wc -l) -le 2 ]; then
        output=$(echo "$output" | grep -v 'res^')
        print -n -u2 "res, "
    fi

    if [ $(tdl :u -F '#zz' | wc -l) -le 2 ]; then
        output=$(echo "$output" | grep -v 'zz^')
        print -n -u2 "zz, "
    fi

    # calendar filters ----------------------------------------------------------- #

    local cal=$(short day tod)

    if echo $cal | grep -Fq " detach"; then
        output=$(echo "$output" | grep -v 'eve^')
        print -n -u2 "eve, "
    else
        if ! echo $cal | grep -Fq "full_detach"; then
            output=$(echo "$output" | grep -v 'cook^' | grep -v 'buy^' | grep -v 'walk^')
            print -n -u2 "cook, buy, walk, "

            if ! echo $cal | grep -Fq "bedtime"; then
                output=$(echo "$output" | grep -v 'floss^')
                print -n -u2 "floss, "
            fi
        fi
    fi

    # big filters ----------------------------------------------------------------- #

    if [[ " $@ " == *" b "* ]]; then
        ob b | while read -r break_item; do
            local item=$(echo "$break_item" | grep -oE '[[:alnum:]_]([[:alnum:]_]| )+$')

            if [[ -z "$item" ]]; then
                continue
            fi

            if printf "%s\n" "$output" | grep -qF "$item"; then
                print -n -u2 "$item, "
                output=$(echo "$output" | grep -v "$item")
            fi
        done
    fi

    # print ------------------------------------------------------ #

    print -u2 "\033[0m"
    output=$(echo $output | rat.sh -pPl "json" | $HOME/.dotfiles/scripts/secret/act_highlight.sh)

    if [[ $* == *"-p"* ]]; then
        (echo $output && printf '\n%.0s' {1..5} && printf "\033[90m$*\033[0m\n%.0s" {1..55}) | less
    else
        echo $output
    fi
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
                local track_cmd="$(tod) $2 $min #u"
            else
                local track_cmd="$2 $min #u"
            fi

            echo "$track_cmd" | to_color.sh yellow
            a "$track_cmd"
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
