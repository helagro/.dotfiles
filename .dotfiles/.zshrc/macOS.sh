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
alias plans="$vault/p && nvim -O p.md break.md"
alias archive="$HOME/Documents/archiver-go/build/macOS"

alias breake="nvim $doc/break-timer/.env"
alias repe="vi $dev/todoist-app/data/repeated.json"

# ------------------------- OTHER FUNCTIONS ------------------------ #

function eve {
    a eve
    day Tom
    echo
    tl d/is.json
    echo
    echo
    tl hb
    echo
    tl p/eve.md
    shortcuts run "Sleep Focus"
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
    clipBoard=$(pbpaste)

    shortcuts run "$1"
    pbpaste

    echo && echo
    echo -n $clipBoard | pbcopy

    tdi
}

# -------------------------- TIMING -------------------------- #

alias sw="$doc/stopwatch/main"
function timer { echo $1 | shortcuts run "Timer"; }

function medd {
    sw $1
    min=$(echo "$1" | cut -d ':' -f1)
    a "medd $min"
}
