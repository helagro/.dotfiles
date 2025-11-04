#!/bin/zsh

exec 3>/dev/tty

sign="-"
pgo=""

_color=1
_prev_audio=1

# ================================= CONSTANTS ================================ #

reminder_text=$(ob "p/auto/ash remind")
init_cols=$(tput cols)

max_pyg_preview=5
wiper=$(printf '%*s' $((max_pyg_preview + 3)) '')

# =============================== USER FEATURES ============================== #

alias pyg="py get --"
alias e="echo"


function len {
    say $(py len)
}

function p {
    say $(py get -- -1p)
}

function py {
    python3 "$MY_SCRIPTS/lang/python/a.py" "$@"
}

function comp {
    if [[ $1 == '1' ]] || [[ -z $1 && -z $ZSH_AUTOSUGGEST_STRATEGY ]]; then
        ZSH_AUTOSUGGEST_STRATEGY=(history)
        audio=$_prev_audio
    else
        unset ZSH_AUTOSUGGEST_STRATEGY

        _prev_audio=$audio
        audio=0
    fi
}

function hist {
    if [[ $1 == '1' ]] || [[ -z $1 && $blank == 1 ]]; then
        comp 1
        blank=0

        my_clear
        divide
    else
        comp 0
        speak=0
        blank=1
    fi
}

function color {
    if [[ $1 == '1' ]] || [[ -z $1 && $_color == 0 ]]; then
        _color=1
        red_mode 0 >&3

        ZSH_HIGHLIGHT_REGEXP+=(
            '#[a-z0-9]+[a-zA-Z0-9]*' fg=green,bold
            ';' fg=yellow,bold
            '&&' fg=yellow,bold

            '@\w+' fg=blue
            '(?:(?<=^)|(?<=\s))(daily|weekly|monthly|yearly|tomorrow|today|yesterday|every week|every day|tod|tom)(?=$|\s)' fg=blue

            '(\s|^)p1(\s|$)' fg=red,bold
            '(\s|^)p2(\s|$)' fg=red,bold
            '\*\*.+\*\*' fg=red,bold

            '(?<=\s|^)p3(?=\s|$)' fg=magenta,underline
            '(?<!\*)\*[^*]+\*(?!\*)' fg=magenta,underline

            '\$\([^\$]+\)' fg=cyan
            '(?<=^|\s)>(-?\d|\w)+(?=$|\s)' fg=cyan
            '^R[[:space:]]' fg=cyan,bold
            '^(c|C|d|D|q)$' fg=cyan,bold
        )
    else
        _color=0
        ZSH_HIGHLIGHT_REGEXP=()
        red_mode 1 >&3
    fi
}


# OPTIONS

blank=0
speak=0
audio=$_prev_audio

# ACCESSABLE

# =========================== SETUP ========================== #

unset HISTFILE SAVEHIST

cmds=(
    'R echo $start_time'
    "R blank="
    "R speak="
    "R audio="
    "R comp"
    "R pyg"
    "R len"
    "R p"
    "R hist"

    '$tea'
    '$is'
    '$sugar'

    '$rd'
    '$rp'
    '$rb'
    '$yd'
    '$db'
    "null"
)

for cmd in "${cmds[@]}"; do
    print -s -- "$cmd"
done

color 1


# ========================= GENERAL FUNCTIONS ======================== #

function on_tab {
    clr
    divide "$start_time"
    a
}

# ======================== A FUNCTIONS ======================= #

function a_ui {
    next_idx=$(py len)
    print_top_right

    if ! command -v a.sh &>/dev/null; then
        echo "a.sh not found!"
        return
    fi

    while :; do
        if [[ $blank == 1 ]]; then
            my_clear
        fi

        m_vared

        # log ------------------------------------------------------------------------ #

        # Add to history & logs
        if [[ $line != ' '* && $line != *'@p'* ]]; then
            $MY_SCRIPTS/lang/shell/utils/log.sh -f a_raw "$line"
            
            print -s -- "$line"
            print -s -- " "
        fi

        # commands ------------------------------------------------------------------- #

        if [[ $line == 'c' ]]; then
            py clear
            my_clear
            
            py map set -k offline_start -v "0" 
            next_idx=0

            start_time="$(date +"%Y-%m-%d %H:%M:%S")"
            divide "$start_time"
            print_top_right
            continue
        elif [[ $line == 'C' ]]; then
            clear
            continue
        elif [[ $line == 'R '* ]]; then
            command=$(echo "$line" | sed -E 's/R[[:space:]]+//g')
            tmpfile=$(mktemp)
            
            eval "$command" >"$tmpfile"
            local output=$(<"$tmpfile")
            
            [[ -n $output ]] && echo " 🖨️ $output"
            rm "$tmpfile"
            continue
        elif [[ $line == 'd' ]]; then
            divide
            continue
        elif [[ $line == 'D' ]]; then
            clear
            divide
            continue
        elif [[ $line == 'q' ]]; then
            echo "quit"
            return 0
        fi

        # expansions ------------------------------------------ #

        local escaped=$(echo "$line" | sed -E \
            -e "s/'/\\'/g" \
            -e 's/`/\\`/g' \
            -e 's/"/\\"/g')
        local once_expanded_line=$(eval echo \"$escaped\")
        local expanded_line=$(eval echo \"$once_expanded_line\" | tr -d '\\')

        if [[ $expanded_line =~ '(?<=^|\s)>((-?\d|\w|\.)+)(?=$|\s)' ]]; then
            pgo=$(py get -- "$match[1]")
            local part_to_replace=">${match[1]}"
            
            expanded_line=$(py replace "$expanded_line" "$part_to_replace" "$pgo")
        else
            pgo=""
        fi

        if [[ "$expanded_line" != "$line" ]]; then
            sign="!"
        fi

        # run -------------------------------------------------------- #

        if [[ $expanded_line == [[:space:]]# ]]; then
            sign="×"
        else
            next_idx=$(($(py len) + 1))
            (
                {
                    py add -- "$expanded_line" &
                    nohup a.sh "$expanded_line" &>/dev/null &
                    wait
                    print_top_right
                } &
            )
            
            [[ $speak == 1 ]] && say "$expanded_line"
            print_if_reminder "$escaped"
        fi
    done
}


# ============================= HELPER FUNCTIONS ============================= #


function print_if_reminder {
    if reminder=$(echo "$reminder_text" | grep -m1 -F -- "- [ ] $1 |"); then
        reminder_parts=("${(@s:|:)reminder}")
        echo " 🔔 ${reminder_parts[2]## }"
    fi
}


function divide {
    local time="$1"
    [[ -z $time ]] && time="$(date +"%Y-%m-%d %H:%M:%S")"
    local text=" $time "
    
    {
        echo -n '\033[33m'
        printf '%*s' $(( init_cols / 2 - ${#text} / 2)) '' | tr ' ' '-'
        printf '%s' "$text"
        echo '\033[0m'
    } >&3
}


function my_clear {
    printf "\033]1337;ClearScrollback\a" >&3
    
    local cols=$(tput cols)
    local whipe_col=$((cols - $max_pyg_preview))
    print -n "\e7\e[1;${whipe_col}H\033[35m${wiper}\033[0m\e8" >&3 

    print_top_right
}


function print_top_right {
    local row=1
    local cols=$(tput cols)
    local whipe_col=$((cols - $max_pyg_preview - 3))

    local old_offline_amt=$(py map get -k offline_amt -d 0)
    local offline_amt=$(cat "$HOME/.dotfiles/tmp/a.txt" | wc -l | tr -d '[:space:]')

    if [[ $old_offline_amt -ne 0 || $offline_amt -ne 0 ]]; then
        if [[ $offline_amt -eq 0 ]]; then
            local offline_start='?'
        else
            if [[ $old_offline_amt -eq 0 ]]; then
                local last_idx=$(($(py len) - 1))
                py map set -k offline_start -v "$last_idx" 
                local offline_start=$last_idx
            else
                local offline_start=$(py map get -k offline_start -d "?")
            fi
        fi

        local text=" ($offline_start|$offline_amt)"
        local col=$((cols - $((${#text})) + 1))

        print -n "\e7\e[${row};${whipe_col}H\033[35m${wiper}\033[0m\e8" >&3
        print -n "\e7\e[1;${col}H\033[33m${text}\033[0m\e8" >&3

        row=$((row + 1))
        py map set -k offline_amt -v "$offline_amt"
    fi

    if [[ -n $pgo ]]; then
        print -n "\e7\e[${row};${whipe_col}H\033[35m${wiper}\033[0m\e8" >&3
        local truncated=" ${pgo[1,$max_pyg_preview]}"

        if (( ${#pgo} > max_pyg_preview )); then
            truncated+="…${pgo[-2,-1]}"
        fi

        local text=" $truncated"
        local col=$((cols - ${#text} + 1))

        sleep 0.1
        print -n "\e7\e[${row};${col}H\033[35m${text}\033[0m\e8" >&3

        pgo=""
    fi
}


function m_vared {
    local padded_num=$(printf "%02d" $next_idx)

    line=""
    vared -p "%B%F{yellow}$padded_num $sign%f%b " line
    [[ $audio == 1 ]] && beep 0.55

    line=$(echo "$line" | tr -d '\\')
    sign="-"
}
