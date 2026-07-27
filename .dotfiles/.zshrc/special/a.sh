#!/bin/zsh

# ================================= CONSTANTS ================================ #

export HISTSIZE=10000

max_pyg_preview=5
beep_volume=0.55

export FZF_DEFAULT_OPTS="--ansi --no-sort --layout=reverse-list --height 20 --border"

# dynamic -------------------------------------------------------------------- #

init_cols=$(tput cols)
wiper=$(printf '%*s' $((max_pyg_preview + 3)) '')
b_counter=0

_python_version=$(python3 --version 2>&1 | awk '{print $2}')
if (( ${_python_version%%.*} < 3 || ( ${_python_version%%.*} == 3 && ${_python_version#*.} < 10 ) )); then
    _disable_python=true
else
    _disable_python=false
fi

# =============================== INTEGRAL USER FEATURES ============================== #

pgo=""
speak=0
extra=1
audio=1

function out_pipe {
    local input=$(cat)
    input=${input## }

    if [[ -z $input ]]; then
        return
    fi
        
    if [[ $1 == '-e' ]]; then
        echo -e "\e[31m$input\e[0m" >&3
    else
        out "$input"
    fi
}

function out {
    local input=$1

    if [[ -n $input ]]; then   
        echo -e "    \e[30m$input\e[0m" >&3
    fi
}

function py {
    if $_disable_python; then
        if [[ $1 == "len" ]]; then
            echo "0"
        fi

        return 0
    fi

    python3 "$MY_SCRIPTS/lang/python/a.py" "$@"
}

function use_extra {
    [[ $1 == $_extra ]] && return

    if [[ $1 == '1' ]] || [[ -z $1 && -z $ZSH_AUTOSUGGEST_STRATEGY ]]; then
        [[ $_hist == 0 ]] && return
        _extra=1
        
        ZSH_AUTOSUGGEST_STRATEGY=(history)
    else
        _extra=0
        unset ZSH_AUTOSUGGEST_STRATEGY
    fi
}

# =========================== SETUP ========================== #

exec 3>/dev/tty
unset HISTFILE SAVEHIST

_sign="-"
_color=1
_prev_audio=1
_silent=0
_hist=1

cols=$(tput cols)

# Reminder setup
reminder_file="/tmp/reminders_sorted.txt"
LC_ALL=C get_reminders | sort > "$reminder_file"


# auto completion ------------------------------------------------------------ #

cmds=(
    'R echo $start_time'
    "R speak="
    "R audio="
    "R extra="
    "R pyg"
    "R len"
    "R p"

    '$tea'
    '$is'
    '$sugar'

    '$rd'
    '$rp'
    '$rb'
    '$rem' # reminder output
    '$yd'
    '$db'
    "null"
)

for cmd in "${cmds[@]}"; do
    print -s -- "$cmd"
done

# call setup functions ------------------------------------------------------- #

use_extra 0
command -v color &>/dev/null && color 1 no_shortcuts

# ========================= GENERAL FUNCTIONS ======================== #

function on_tab {
    clr
    divide "$start_time"
    a
}

# ======================== MAIN FUNCTION ======================= #

function a_ui {
    next_idx=$(py len)
    print_top_right "$pgo"

    if ! command -v a.sh &>/dev/null; then
        echo "a.sh not found!"
        return
    fi

    while :; do
        if [[ $_hist == 0 ]]; then
            my_clear
        fi
        should_extra -u -c 2>/dev/null && use_extra 1 || use_extra 0

        take_input

        # Ignored inputs
        if [[ -z $line || $line == "#" ]]; then
            printf '\033[1A\033[J'
            continue
        fi

        # commands ------------------------------------------------------------------- #

        # Bin
        if [[ $line == 'B '* ]]; then
            if [[ ${#line} -lt $(($(tput cols) - 8)) ]]; then
                echo -ne '\033[s\033[0A'
                echo -ne "\033[1;90m $(printf "%02d" $b_counter)\033[0m"
                echo -ne '\033[u'
            else
                out $b_counter
            fi

            b_counter=$((b_counter + 1 % 100))
            _sign="×"
            line=""
            continue
        fi

        log_line "$line"

        # Clear with reset
        if [[ $line == 'c' ]]; then
            # NOTE - must be first
            map -s done.boot || (nohup a.sh "$(day -1) ash $next_idx" >/dev/null &)

            py clear
            my_clear
            fc -p

            map -m set ash.offline_start 0 
            next_idx=0
            
            command -v reset_day &>/dev/null && reset_day
            start_time="$(date +"%Y-%m-%d %H:%M:%S")"
            divide "$start_time"
            continue
        # Divide
        elif [[ $line == 'd' ]]; then
            divide
            continue
        # History toggle
        elif [[ $line == 'h' ]]; then
            hist
            continue
        # Quit
        elif [[ $line == 'q' ]]; then
            echo "quit"
            return 0
        # Raw input
        elif [[ $line == 'r' ]]; then
            line="$(cat)"
        # Run
        elif [[ $line == 'R '* ]]; then
            command=$(echo "$line" | sed -E 's/R[[:space:]]+//g')
            eval "$command" > >(out_pipe) 2> >(out_pipe -e)
            continue
        # Toggle silent mode
        elif [[ $line == 'S' ]]; then
            if [[ $_silent == 2 ]]; then
                _silent=0
            else
                _silent=2
            fi
            continue
        # Update
        elif [[ $line == 'U'* ]]; then
            if is_online; then
                local u_arg=$(echo "$line" | sed -E 's/U[[:space:]]*//g')

                # Verbose for debugging. Keep as is useful from time to time
                if [[ $u_arg == '-v'* ]]; then
                    local verbose=1
                    u_arg=$(echo "$u_arg" | sed -E 's/-v[[:space:]]*//g')
                    echo "BEFORE: $u_arg"
                fi

                [[ -z $u_arg ]] && u_arg=-1

                # Search, if the argument is a number
                local search=$u_arg
                [[ $u_arg == (-|)<-> ]] && search=$(pyg $u_arg)

                [[ -n $verbose ]] && echo "AFTER: $search"
                tdls -p | grep -i -- "$search" | tac | in.sh --format=a
            else
                vim "$HOME/.dotfiles/tmp/a.txt"
            fi

            continue
        fi

        # run -------------------------------------------------------- #

        expand_item "$line" expanded_line
        if [[ $_silent != 0 || $line == " "* ]]; then
            expanded_line="$expanded_line @p"
        fi
        if [[ $line != $expanded_line ]]; then
            _sign="!"
        fi

        if [[ $expanded_line == [[:space:]]# ]]; then
            _sign="×"
        else
            # next_idx=$(($(py len) + 1))
            next_idx=$((next_idx + 1))

            ({
                py add -- "$expanded_line" &
                nohup a.sh "$expanded_line" >/dev/null &
                wait
                print_top_right "$pgo"
            }&)
        fi
            
        if [[ $_silent == 0 ]]; then
            [[ $speak == 1 && $_silent != 0 ]] && my_speak "$expanded_line"
            handle_if_special "$line"
        fi
    done
}


# ============================= HELPER FUNCTIONS ============================= #

function expand_item {
    local escaped=$(echo "$1" | sed -E \
        -e "s/'/\\'/g" \
        -e 's/"/\\"/g')

    if [[ "$escaped" == '`'* ]] && $(py oddBackticks "$escaped"); then
        escaped="$escaped\`"
    fi

    local expanded_line_loc=$(eval echo \"$escaped\" 2> >(out_pipe -e) | tr -d '\\')

    if [[ $expanded_line_loc =~ '(?<=^|\s)>((-?\d|\w|\.)+)(?=$|\s)' ]]; then
        pgo=$(py get -- "$match[1]")
        local part_to_replace=">${match[1]}"
        
        expanded_line_loc=$(py replace "$expanded_line_loc" "$part_to_replace" "$pgo")
    else
        pgo=""
    fi

    printf -v "$2" "%s" "$expanded_line_loc"
}

function my_speak { 
    say -v samantha -r 500 "$*"
}

function handle_if_special {
    # NOTE - For performance
    if [[ "$1" != *[\$#0-9]* ]]; then
        return
    fi

    local input=$(echo "$1" | sed 's/#/TO /g' | sed 's/$mb/TO b/g' | tr -d '\n')

    local dest=$(echo "$input" | grep -o 'TO [A-Za-z0-9_]\+' | tr -d '\n')
    if [[ -n $dest ]]; then
        _handle_if_special "$dest"
    fi

    local parts=(${(s:;:)input})
    for p in $parts; do
        p="${${p##[[:space:]]#}%%[[:space:]]#}"

        parts_input="${p//[1-9][0-9.]#/*}"
        _handle_if_special "$parts_input"
        ({ sleep 0.1 && _handle_if_special "$parts_input -A" }&)
    done
}

function _handle_if_special {
    local reminders=$(look -f -- ": '$1' ;" "$reminder_file")

    while read -r reminder; do
        if [[ -n $reminder ]]; then

            local reminder_parts=("${(@s:;:)reminder}")
            local reminder_text="${(j:;:)reminder_parts[2, -1]## }"

            if [[ $reminder_text == "*"* ]]; then
                should_extra 2>/dev/null || continue

                rem=${reminder_text//'*'/}
                out "$rem"
            elif [[ $reminder_text == "\`"* ]]; then
                should_extra -u -c 2>/dev/null || continue

                cmd=${reminder_text//\`/}
                ttab -d '' -w $cmd
            else
                local expanded=$(eval "$reminder_text" 2> >(out_pipe -e) | tr -d '\\')
                echo "$expanded\n" >> ~/Desktop/ash_reminder.txt
                ( nohup a.sh "$expanded" >/dev/null & )
            fi
        fi
    done <<< "$reminders"
}

function my_clear {
    if [[ $_hist == 0 ]]; then
        printf "\033]1337;ClearScrollback\a\e[%s;1H" "$(tput lines)" >&3
    else
        printf "\033]1337;ClearScrollback\a" >&3
    fi
    
    local cols=$(tput cols)
    local wipe_col=$((cols - $max_pyg_preview))
    print -n "\e7\e[1;${wipe_col}H\033[35m${wiper}\033[0m\e8" >&3 

    ( print_top_right "" & )
}

function print_top_right {
    local row=1
    local wipe_col=$((cols - $max_pyg_preview - 3))
    local msg="$1"
    
    [[ $2 != "-C" ]] && cols=$(tput cols)

    local old_offline_amt=$(map -m ash.offline_amt 0)
    local offline_amt=$(cat "$HOME/.dotfiles/tmp/a.txt" | wc -l | tr -d '[:space:]')

    # offline info --------------------------------------------------------------- #

    if [[ $old_offline_amt -ne 0 || $offline_amt -ne 0 ]]; then
        if [[ $offline_amt -eq 0 ]]; then
            local offline_start='?'
        else
            if [[ $old_offline_amt -eq 0 ]]; then
                local last_idx=$(($(py len) - 1))
                map -m set ash.offline_start "$last_idx" 
                local offline_start=$last_idx
            else
                local offline_start=$(map -m ash.offline_start "?")
            fi
        fi

        local text=" ($offline_start|$offline_amt)"
        local col=$((cols - $((${#text})) + 1))

        print -n "\e7\e[${row};${wipe_col}H\033[35m${wiper}\033[0m\e8" >&3
        print -n "\e7\e[1;${col}H\033[33m${text}\033[0m\e8" >&3

        row=$((row + 1))
        map -m set ash.offline_amt "$offline_amt"
    fi

    # expansion info ------------------------------------------------------------- #

    if should_extra 2>/dev/null; then
        if [[ -n $1 ]]; then
            print -n "\e7\e[${row};${wipe_col}H\033[35m${wiper}\033[0m\e8" >&3
            local truncated=" ${msg[1,$max_pyg_preview]}"

            if (( ${#msg} > max_pyg_preview )); then
                truncated+="…${msg[-2,-1]}"
            fi

            local text=" $truncated"
            local col=$((cols - ${#text} + 1))

            sleep 0.1
            print -n "\e7\e[${row};${col}H\033[35m${text}\033[0m\e8" >&3
        fi
    else
        print -n "\e7\e[${row};${wipe_col}H\033[35m${wiper}\033[0m\e8" >&3
        print -n "\e7\e[${row};${cols}H\033[35m?\033[0m\e8" >&3 
    fi
}

function take_input {
    local zero_padded_num=$(printf "%02d" $next_idx)
    (( ${#zero_padded_num} < 3)) && local padded_num=" $zero_padded_num" || local padded_num="$zero_padded_num" 
    local prompt="$padded_num $_sign"

    if [[ $_color -eq 1 ]]; then
        prompt="%F{yellow}$prompt%f"
    else
        prompt="%F{red}$prompt%f"
    fi

    line=""

    if [[ $_silent == 0 ]]; then
        vared -p "%B$prompt%b " line
    else
        print -n -P "$prompt "
        read -s "line?"
        echo
    fi

    # NOTE - Is here to get instant feedback
    [[ $audio == 1 && $_extra == 1 ]] && beep $beep_volume

    line=$(echo "$line" | tr -d '\\')
    _sign="-"
}

# triggered by commands ------------------------------------------------------ #

function divide {
    local time="$1"
    [[ -z $time ]] && time="$(date +"%Y-%m-%d %H:%M:%S")"
    local text=" $time "
    
    {
        echo -n '\033[33m  '
        printf '%*s' $(( init_cols / 2 - ${#text} / 2 - 4)) '' | tr ' ' '-'
        printf '%s' "$text"
        echo '\033[0m'
    } >&3
}

function hist {
    if [[ $1 == '1' ]] || [[ -z $1 && $_hist == 0 ]]; then
        _hist=1

        my_clear
        divide
        audio=$_prev_audio
    else
        speak=0
        _hist=0
        
        _prev_audio=$audio
        audio=0
    fi
}