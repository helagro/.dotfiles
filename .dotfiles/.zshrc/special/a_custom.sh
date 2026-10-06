#!/bin/zsh

# Misc
is="#zz @wifi @eye > is"
p1="#other p1"
florinef="get florinef in 122 days"

# Special activities
reboot='`sudo shutdown -r now` #b'
eat='`eat` #b @mv'
exor='`exor` #b @mv'
dish="dish - _$chore_reminder_ #b @mv @home"

# Run
rb="@run #other :b"
rp="@run #other :p"
pom="@run #other :p tom"

# Tags
mv="@mv @home"
bo="@out #b"
bm="@mv @home #b"
bmt="@mv @home @tod #b"
h="@home"

alias tea="drink tea"
alias water="drink water"

# Time shortcuts
yd="yesterday"
yyd="two days ago"

# ================================= FUNCTIONS ================================ #

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

function remind_eat {
    if in_window.sh "$(map routine.lunch 11:00)" 14:00; then
        ! map -s done.lunch && is_home && out 'eat lunch'
    elif in_window.sh "$(map routine.dinner 17:00)" 21:00; then
        ! map -s done.dinner && is_home && out 'eat dinner'
    fi
}

# manually executed ------------------------------------------------------------ #

function hr {
    local hour="$1"
    local dest="$2"
    local message="$(in)"

    if [[ -z $hour || -z $dest || -z $message ]]; then
        out "Missing hour, dest, or message"
        return 1
    fi

    echo "#hour $hour ; + :$dest $message"
}

function hrb {
    hr "$1" b
}

function tv {
    echo "#b \`tv $1 &<wbr>& echo\` @p @tod"
}

function dk {
    local lines=$1
    [[ -z $lines ]] && lines=1

    printf "\033[$((1+$lines))A\033[J" >&3
}

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

function exp {
    if [[ -n $1 ]]; then
        local food="$1"
    else
        local food=$(in 'food: ')
    fi

    local output="#docok $1"
    local hard_deadline=$(in 'hard deadline: ')
    if [[ -n $hard_deadline ]]; then
        output="$output && #b **finish $1** $hard_deadline"
    fi
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


