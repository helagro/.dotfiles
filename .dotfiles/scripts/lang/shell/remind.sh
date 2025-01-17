#!/bin/zsh
note_name="remind"
[ -n "$1" ] && note_name="$1"
note=$($HOME/.dotfiles/scripts/path/ob.sh remind)
matches=$(echo $note | $HOME/.dotfiles/scripts/path/state_switch.sh)

choosen_one=$(echo $matches | shuf -n 1)
echo $choosen_one | sed 's/ \*-IF.*//g' | tr -d '\n'
