#!/bin/zsh

ob.sh b

# ======================== CALCULATED ======================== #
(
    if command -v state.sh &>/dev/null && state.sh -s stress; then
        echo "relaxation content"
    fi
    windows.sh
    battery_level=$(pmset -g batt | grep -o '[0-9]*%' | tr -d '%')
    if [ $battery_level -lt 30 ]; then
        echo "Charge: $battery_level%"
    fi
) | to_color.sh green

# =========================== OTHER ========================== #

echo
toggl current 2>/dev/null | grep 'Project' | to_color.sh magenta
