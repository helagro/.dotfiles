#!/bin/zsh

# Misc
is="#zz @wifi @eye > is"
p1="#other p1"

# Special activities
reboot='> sudo shutdown -r now #b'
eat='> eat #b @mv'
exor='> exor #b @mv'

# Run
rb="@run #other :b"
rp="@run #other :p"
pom="@run #other :p tom"

# Tags
mv="@mv @home"
mb="@mv @home #b"
mtb="@mv @home @tod #b"
h="@home"
pret="@return && c pret"

alias tea="drink tea"
alias water="drink water"

# time ----------------------------------------------------------------------- #


# Time shortcuts
yd="yesterday"
yyd="two days ago"

# ================================= FUNCTIONS ================================ #

function tv {
    echo "#b \`tv $1 &<wbr>& echo\` @p @tod"
}

function dk {
    local lines=$1
    [[ -z $lines ]] && lines=1

    printf "\033[$((1+$lines))A\033[J" >&3
}

function day_part {
    if is_dawn; then
        out 'is_dawn'
    elif is_day; then
        out 'is_day'
    else
        out 'is_eve'
    fi
}

function ut {
    out_part "$@" | out_pipe

    map.sh -s s.social && _hist=0
    printf '\033c' >&3
}

# manually executed ------------------------------------------------------------ #

alias pyg="py get --"

function len {
    my_speak $(py len)
}

function p {
    my_speak $(py get -- -1p)
}

function share {
    echo "#share ![$1]($1)"
}

# utils ---------------------------------------------------------------------- #

alias e="echo"

function in {
    [[ $audio == 1 && $_extra == 1 ]] && beep $beep_volume frog
    
    print -n "  > $1" >&3
    local stdin_input=$(head -n 1 </dev/tty | tr -d '\n' )
    
    if [[ -z $stdin_input ]]; then
        return 1
    fi

    if [[ -n $1 ]]; then
        printf '%s' "$1 $stdin_input" 
    else
        printf '%s' "$stdin_input"    
    fi

}


