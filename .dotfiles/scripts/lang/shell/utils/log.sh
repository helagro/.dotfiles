#!/bin/zsh

do_output=false

if [[ "$1" == "-o" ]]; then
    shift
    do_output=true
fi

file_name="$HOME/.dotfiles/logs/$1.log"
shift

if [[ -n "$*" ]]; then
    new_content="$*"
else
    new_content=$(cat)
fi

echo "$new_content" >>$file_name
if $do_output; then
    echo "$new_content"
fi

log_size=$(wc -l $file_name | awk '{print $1}')
excess=$(expr $log_size - 2000)

if [ $excess -gt 0 ]; then
    del_amt=$(expr $excess + 500)
    sed -i '' 1,$del_amt'd' $file_name
fi
