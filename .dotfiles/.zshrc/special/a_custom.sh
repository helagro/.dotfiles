#!/bin/zsh

# Misc
is3="#zz @wifi @eye p3 is"
is="#zz @wifi @eye is"

# Special activities
cook='#b **cook** @home @mv'
reboot='> sudo shutdown -r now #b'
pack='[[pack]]'
eat='> eat #b @mv'

# Run
rb="#run :b"
rd="#run :day"
rp="#run :p"
pom="#run :p tom"

# Tags
mv="@mv @home"
mb="@mv @home #b"
mtb="@mv @home @tod #b"
h="@home"
pret="@return && c pret"

# Tracking
s="s $(is_online || echo '>0T') @rm #u"
i="i $(is_online || echo '>0T') @rm #u"

alias tea="drink tea"
alias water="drink water"

# time ----------------------------------------------------------------------- #

dawn_start='03:00'
day_start='12:00'
eve_start='18:00'

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

# manually executed ------------------------------------------------------------ #

alias pyg="py get --"

function len {
    my_speak $(py len)
}

function p {
    my_speak $(py get -- -1p)
}

# utils ---------------------------------------------------------------------- #

alias e="echo"

function in {
    [[ $audio == 1 && $_extra == 1 ]] && beep $beep_volume frog
    
    print -n "  > $1" >&3
    local input=$(head -n 1 </dev/tty | tr -d '\n' )

    if [[ -n $1 ]]; then
        printf '%s' "$1 $input" 
    else
        printf '%s' "$input"    
    fi

    if [[ -z $input ]]; then
        return 1
    fi
}

is_dawn () { in_window.sh $dawn_start $day_start; }
is_day () { in_window.sh $day_start $eve_start; }
is_eve () { in_window.sh $eve_start $dawn_start; }

