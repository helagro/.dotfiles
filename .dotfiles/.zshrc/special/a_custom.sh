#!/bin/zsh

# Misc
dk='$(dk 1)'
is="#zz @wifi p3 is"
reboot='> sudo shutdown -r now #b'

# Run
rp="#run :p"
rb="#run :b"
rd="#run :day"

# Tags
mv="@mv @home"
mvb="@mv @home #b"
h="@home"
pret="@return && c pret"

# Tracking
t="$(is_online || echo '>0T #u') @rm t"
s="s $(is_online || echo '>0T') @rm #u"

# Shower
shower='#b :tmp shower ; $(date +"%Y-%m-%d %H:%M:%S") @home @mv<span hidden>&<wbr>& decomp 15</span>'
showered='#tmp shower ; $(date +"%Y-%m-%d %H:%M:%S") && decomp 15'

# Tea
tea3='$(tea_fun 300)'
tea5='$(tea_fun 500)'
tea8='$(tea_fun 800)'

# time ----------------------------------------------------------------------- #

dawn_start='03:00'
day_start='12:00'
eve_start='18:00'

# Time shortcuts
yd="yesterday"
yyd="two days ago"

# ================================= FUNCTIONS ================================ #


function dk {
    printf "\033[$((1+$1))A\033[J" >&3
}

function sugar_fun {
    is_home && is_home_var=true || is_home_var=false

    if $is_home_var && in_window.sh 13:00 $(map routine.latest_dinner 18:00) && ! map -s done.mouthwash; then
        echo "> map set done.mouthwash true #b"
        return
    fi

    if $is_home_var && ! map -s done.floss; then
        echo "> map set done.floss true #b"
        return
    fi

    if ! map -s done.gum; then
        echo "> map set done.gum true #b"
        return
    fi
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

alias is_dawn="in_window.sh $dawn_start $day_start"
alias is_day="in_window.sh $day_start $eve_start"
alias is_eve="in_window.sh $eve_start $dawn_start"

