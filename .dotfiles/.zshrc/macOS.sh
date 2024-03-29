vault="$HOME/Dropbox/Apps/remotely-save/vault"
doc="$HOME/Documents"
dev="$HOME/Developer"


alias vi="nvim"
alias c="bc -le"
alias plans="$vault/p && nvim -O p.md break.md"
alias eve="a eve && day Tom && echo && me && echo && tl p/eve.md && shortcuts run 'Sleep Focus'"
alias breake="nvim $doc/break-timer/.env"

function e {
    if [ -d "$dev/$1" ]; then
        code "$dev/$1"
    elif [ -d "$doc/$1" ]; then
        code "$doc/$1"
    elif [ -e "$vault/$*.md" ]; then
        nvim "$vault/$*.md"
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

# --------------------- TERMINAL SETTINGS -------------------- #

plugins=(git)

unsetopt inc_append_history
unsetopt share_history

# Disable zsh-autocompletion on paste
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

 pastefinish() {
   zle -N self-insert $OLD_SELF_INSERT
 }
 zstyle :bracketed-paste-magic paste-init pasteinit
 zstyle :bracketed-paste-magic paste-finish pastefinish

# -------------------------- TIMING -------------------------- #

alias sw="$doc/stopwatch/main"
function timer { echo $1 | shortcuts run "Timer"; }

function medd {
    sw $1
    min=$(echo "$1" | cut -d ':' -f1)
    a "medd $min"
}
