#!/bin/zsh

ob.sh b

# ======================== CALCULATED ======================== #
cal=$(echo tod | shortcuts run day --output-type public.plain-text)

(
    if command -v state.sh &>/dev/null && state.sh -s stress; then
        echo "relaxation content"
    fi

    windows.sh

    $HOME/.dotfiles/scripts/lang/shell/battery.sh 30

) | to_color.sh blue

# =========================== OTHER ========================== #

echo
toggl current 2>/dev/null | grep 'Project' | to_color.sh magenta
