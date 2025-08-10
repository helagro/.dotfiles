#!/bin/zsh

(nohup $HOME/.dotfiles/scripts/path/windows.sh >/dev/null &)

# =============================== DEPENDENCIES =============================== #

export PATH="/opt/homebrew/bin:$PATH"

if ! command -v "shuf" &>/dev/null; then
    echo "ERR: shuf command not found"
    exit 1
fi


# display if late -------------------------------------------- #

cal=$(echo tod | shortcuts run day --output-type public.plain-text)

if ! echo $cal | grep -Fq "full_detach"; then
    if ! echo $cal | grep -Fq "bed_time"; then
        print -n "bed_time"
        exit 0
    fi

    print -n "full_detach"
    afplay $HOME/.dotfiles/assets/audio/brown_noise.mp3
    exit 0
fi

# find items ------------------------------------------------- #

note_name="auto/remind"
[ -n "$1" ] && note_name="$1"

note=$($HOME/.dotfiles/scripts/path/note/ob.sh "$note_name")
matches=$(echo $note | $HOME/.dotfiles/scripts/path/state/state_switch.sh)

# choose one ------------------------------------------------- #

choosen_one=$(echo $matches | shuf -n 1)
print -n $choosen_one | sed 's/ \*-IF.*//g'
