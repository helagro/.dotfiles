#!/bin/zsh


if command -v bat >/dev/null 2>&1; then
    bat "$@" --theme=ansi
elif command -v batcat >/dev/null 2>&1; then
    batcat "$@" --theme=ansi
else

    if [[ $* == *-* ]]; then
        cat
    else
        cat "$@"
    fi
fi
