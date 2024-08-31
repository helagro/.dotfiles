# -------------------------- SOURCE -------------------------- #

if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ------------------------- OTHER ------------------------ #

export PATH="/Users/h/Library/Python/3.9/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"

if command -v rbenv &>/dev/null; then
    eval "$(rbenv init -)"
fi

# ----------------------- OTHER ALIASES ---------------------- #

alias vi="nvim"
alias archive="$HOME/Documents/archiver-go/build/macOS"

alias breake="nvim $doc/break-timer/.env"
alias repe="vi $dev/todoist-app/data/repeated.json"

# ------------------------- OTHER FUNCTIONS ------------------------ #

function pass {
    op item get "$@" --reveal --fields password | pbcopy
    op item get "$@" --reveal
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

function inv {
    if [[ $1 == "1" ]]; then
        1="on"
    fi

    echo -n $1 | shortcuts run "Invert"
}

function day {
    local clipBoard=$(pbpaste)

    shortcuts run "$1"
    pbpaste

    echo && echo
    echo -n $clipBoard | pbcopy

    tdi
}

# -------------------------- ROUTINE ------------------------- #

function dawn {
    shortcuts run "dnd off"
    a dawn
    day Tod
    ob dawn
}

function eve {
    a eve
    day Tom
    echo
    tl hb
    echo
    ob eve
    shortcuts run "Sleep Focus"
}

# -------------------------- TIMING -------------------------- #

function timer { echo $1 | shortcuts run "Timer"; }

function medd {
    shortcuts run "dnd on"
    sw $1 "medd"
    shortcuts run "dnd off"
}

function sw {
    local start_time=$(date +%s)

    caffeinate -disu -i $doc/stopwatch/main "$1"

    if [ $? -ne 2 ]; then
        asciiquarium
    fi

    local end_time=$(date +%s)
    local min=$((($end_time - $start_time) / 60))

    if [ -n "$2" ] && [ "$min" -ne 0 ]; then
        a "$2 $min"
    fi
}
