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
                'p3' fg=magenta,underline
                'p1' fg=red,bold
                '\*\*.+\*\*' fg=red,bold
                '(?<!\*)\*[^*]+\*(?!\*)' fg=magenta,underline
                ';' fg=yellow,bold
                '@\w+' fg=blue
            )
        fi

        a
    elif [[ $role == "ai" ]]; then
        if is_dark; then
            export AICHAT_LIGHT_THEME=0
        else
            export AICHAT_LIGHT_THEME=1
        fi

        gpt4
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
    local focus_mode="off"
    local theme=0

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
        -h | --help)
            echo "Usage: dawn [-f <focus_mode>] [-t <theme>]"
            return 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
        esac
    done

    short focus "$focus_mode"
    short night_shift 0
    short focus
    theme $theme
    wifi on

    a "dawn #u"
    day tod
    ob dawn

    tl streaks
    ob rule
    ob p
    ob b

    later
}

function eve {
    # Silent tasks
    a "eve #u"
    echo "" >$vault/p/rule.md
    echo "" >$vault/p/p.md

    day tom
    echo

    # Show stats
    echo -n temp:
    sens temp
    echo "podd:"
    is podd 1
    echo "tv_min:"
    is tv_min 1

    tl hb

    echo
    ob eve

    short focus sleep
    short night_shift 1
    theme 1

    a "p_ett $(tdis | lines | tr -d '[:space:]') s #u"

    if [[ ! " $@ " == *" -l "* ]]; then
        sleep 3
        short phondo "flight mode"
    else
        echo "-l SO no phone flight mode"
    fi

}

function bedtime {
    sens temp

    if [[ ! " $@ " == *" -l "* ]]; then
        wifi off
        short phondo "flight mode"
    else
        echo "-l SO not turning off wifi"
        echo "-l so no phone flight mode"
    fi

    short focus sleep
    ob bedtime
}

# -------------------------- TIMING -------------------------- #

alias timer="short timer"

function medd {
    if [[ ! $2 == "-l" ]]; then
        short focus on
    fi

    sw $1 "medd"

    if [[ ! $2 == "-l" ]]; then
        short focus off
    fi
}

function sw {
    if [[ $1 == "help" ]]; then
        echo "Usage: sw <duration> <activity>"
        return 0
    fi

    local start_time=$(date +%s)

    caffeinate -disu -i $doc/stopwatch/main "$1"

    if [ $? -ne 2 ]; then
        asciiquarium
    fi

    local end_time=$(date +%s)
    local min=$((($end_time - $start_time) / 60))

    if [ -n "$2" ] && [ "$min" -ne 0 ]; then
        a "$2 $min #u"
    fi
}
