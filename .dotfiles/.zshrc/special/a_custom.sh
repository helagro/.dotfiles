#!/bin/zsh

# Misc
is="#zz @wifi p3 is"

# Special activities
cook='#b **cook** @home @mv'
reboot='> sudo shutdown -r now #b'
pack='[[pack]]'
#
shower='#b :tmp shower ; $(date +"%Y-%m-%d %H:%M:%S") @home @mv<span hidden>&<wbr>& decomp 15</span>'
showered='#tmp shower ; $(date +"%Y-%m-%d %H:%M:%S") && decomp 15'

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
    printf "\033[$((1+$1))A\033[J" >&3
}

function sugar_fun {
    if ob b | grep -q 'teeth'; then
        return
    fi

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

    if ! map -s done.salt; then
        echo "> map set done.salt true #b"
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

