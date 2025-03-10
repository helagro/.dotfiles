#!/bin/zsh
# Calling this during different windows of time will make things happen :)

# ========================= FUNCTIONS ======================== #

function before {
    time_diff.sh -p $1 $2 >/dev/null
}

function in_window {
    if [[ $1 == "-o" ]]; then
        shift
        before $1 $last_time && before $last_time $2 && return 1
    fi

    before $1 $now && before $now $2
}

# =========================== MAIN =========================== #

now=$(date +"%H:%M")
last_time=$(cat $HOME/.dotfiles/tmp/windows.txt)
echo "$now" >$HOME/.dotfiles/tmp/windows.txt

remind_time=$(date -v +30M +"%H:%M")

# ========================== WINDOWS ========================= #

# water ------------------------------------------------------ #

local water_limit=750
if in_window "16:00" "20:00"; then
    water=$(conda run -n main python3 "$HOME/.dotfiles/scripts/lang/python/exist.py" water 1 | jq '.[]')

    if [[ $water -lt $water_limit ]]; then
        echo "hydrate - ($water < $water_limit)"
    fi
fi

# tt --------------------------------------------------------- #

if $HOME/.dotfiles/scripts/path/note/ob.sh b | grep -qFe "- [ ] tt"; then
    if in_window "12:00" "18:00" && in_window -o "12:00" "18:00"; then
        $HOME/.dotfiles/scripts/path/task/a.sh "!($remind_time) $remind_time tt @rm"
    fi
fi
