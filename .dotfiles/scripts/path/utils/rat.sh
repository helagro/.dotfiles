#!/bin/zsh


if command -v bat >/dev/null 2>&1; then
    bat "$@" --theme=ansi
elif command -v batcat >/dev/null 2>&1; then
    batcat "$@" --theme=ansi
else

    # Strips flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*)
            shift
            ;;
            *)
            break
            ;;
        esac
    done

    cat "$@"
fi
