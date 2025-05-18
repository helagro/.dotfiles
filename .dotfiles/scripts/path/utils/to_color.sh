#!/bin/zsh

color="$1"

# Define ANSI color codes using \x1b for compatibility
typeset -A colors
colors=(
    black "\x1b[0;30m"
    red "\x1b[1;31m"
    green "\x1b[1;32m"
    yellow "\x1b[1;33m"
    blue "\x1b[1;34m"
    magenta "\x1b[1;35m"
    cyan "\x1b[1;36m"
    white "\x1b[1;37m"
    gray "\x1b[0;37m"
    reset "\x1b[0m"
)

# Validate color
if [[ -z ${colors[$color]} ]]; then
    echo "Unknown color: $color" >&2
    return 1
fi

# Apply color to stdin using sed
sed "s/.*/${colors[$color]}&${colors[reset]}/"
