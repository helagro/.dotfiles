#!/bin/zsh
# Used for break timer

$HOME/.dotfiles/scripts/path/windows.sh >/dev/null 2>&1

# find items ------------------------------------------------- #

note_name="auto/remind"
[ -n "$1" ] && note_name="$1"
note=$($HOME/.dotfiles/scripts/path/note/ob.sh "$note_name")
matches=$(echo $note | $HOME/.dotfiles/scripts/path/state_switch.sh)

# choose one ------------------------------------------------- #

choosen_one=$(echo $matches | shuf -n 1)
echo $choosen_one | sed 's/ \*-IF.*//g' | tr -d '\n'
