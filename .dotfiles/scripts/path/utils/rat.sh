#!/bin/zsh

function my_cat {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -p | -P |--)
            shift 
            ;;
        -l)
            shift 2 
            ;;
        *)
            break 
            ;;
        esac
    done

    cat "$@"
}

if $is_red_tab; then
    my_cat "$@"
    exit
fi

if command -v bat >/dev/null 2>&1; then
    bat "$@" --theme=ansi
elif command -v batcat >/dev/null 2>&1; then
    batcat "$@" --theme=ansi
else
    my_cat "$@"
fi
