#!/bin/zsh

battery_info=$(pmset -g batt)
battery_level=$(echo $battery_info | grep -o '[0-9]*%' | tr -d '%')
if [[ $battery_level -lt $1 && $battery_info = *Battery* ]]; then
    echo "Charge: $battery_level%"
fi
