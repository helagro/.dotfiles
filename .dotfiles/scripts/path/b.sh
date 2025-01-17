#!/bin/zsh

# ------------------------- FUNCTIONS ------------------------ #

function before {
    time_diff.sh -p $1 $2 >/dev/null
}

function in_window {
    if [[ $1 == "-o" ]]; then
        shift
        before $1 $last_time && before $last_time $2 && return 1
    fi

    before $1 $now && before $now $2
}

# ------------------------- MAIN ------------------------ #

now=$(date +"%H:%M")
last_time=$(cat $HOME/.dotfiles/tmp/b.txt)
echo "$now" >$HOME/.dotfiles/tmp/b.txt

if in_window "16:30" "19:30"; then
    echo "hydrate"
fi

ob.sh b
