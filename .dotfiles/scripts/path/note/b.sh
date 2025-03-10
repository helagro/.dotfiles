#!/bin/zsh

ob.sh b

# ======================== CALCULATED ======================== #
(
    if command -v state.sh &>/dev/null && state.sh -s stress; then
        echo "relaxation content"
    fi

    if ! echo $cal | grep -Fq "detach"; then
        echo "prepp bedtime"
    fi

    windows.sh

    battery_info=$(pmset -g batt)
    battery_level=$(echo $battery_info | grep -o '[0-9]*%' | tr -d '%')
    if [[ $battery_level -lt 30 && $battery_info = *Battery* ]]; then
        echo "Charge: $battery_level%"
    fi
) | to_color.sh blue

# =========================== OTHER ========================== #

echo
toggl current 2>/dev/null | grep 'Project' | to_color.sh magenta
