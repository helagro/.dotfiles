#!/bin/zsh

if command -v bat >/dev/null 2>&1; then
    bat "$@"
elif command -v batcat >/dev/null 2>&1; then
    batcat "$@"
else
    cat
fi
