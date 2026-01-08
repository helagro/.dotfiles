#!/bin/zsh

# =================================== SETUP ================================== #

exec 3>/dev/tty

_python_version=$(python3 --version 2>&1 | awk '{print $2}')
if (( ${_python_version%%.*} < 3 || ( ${_python_version%%.*} == 3 && ${_python_version#*.} < 10 ) )); then
    _disable_python=true
else
    _disable_python=false
fi

_sign="-"
_color=1
_prev_audio=1
_silent=0
_hist=1

# ================================= CONSTANTS ================================ #

init_cols=$(tput cols)

max_pyg_preview=5
wiper=$(printf '%*s' $((max_pyg_preview + 3)) '')

# =============================== USER FEATURES ============================== #

pgo=""
speak=0
extra=1
audio=$_prev_audio

alias pyg="py get --"
alias e="echo"

function in {
    print -n "  > $1" >&3
    local input=$(head -n 1 </dev/tty | tr -d '\n' )

    if [[ -n $1 ]]; then
        printf '%s' "$1 $input" 
    else
        printf '%s' "$input"    
    fi
}

function out {
    echo -e "    \e[30m$1\e[0m" >&3
}

function len {
    my_speak $(py len)
}

function p {
    my_speak $(py get -- -1p)
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

function color {
    if [[ $1 == '1' ]] || [[ -z $1 && $_color == 0 ]]; then
        _color=1
        print -n "\033]111\007" >&3
        [[ -z $2 ]] && red_mode 0 >&3

        ZSH_HIGHLIGHT_REGEXP+=(
            '#[a-z0-9]+[a-zA-Z0-9]*' fg=green,bold
            ';' fg=yellow,bold
            '&&' fg=yellow,bold

            '@\w+' fg=blue
            '(?:(?<=^)|(?<=\s))(daily|weekly|monthly|yearly|tomorrow|today|yesterday|every week|every day|tod|tom)(?=$|\s)' fg=blue

            '(\s|^)p1(\s|$)' fg=red,bold
            '(\s|^)p2(\s|$)' fg=red,bold
            '\*\*.+\*\*' fg=red,bold
            # '%%.+%%' fg=black

            '(?<=\s|^)p3(?=\s|$)' fg=magenta,underline
            '(?<!\*)\*[^*]+\*(?!\*)' fg=magenta,underline

            '`.+`' fg=cyan
            '\$\([^\$]+\)' fg=cyan
            '(?<=^|\s)>(-?\d|\w)+(?=$|\s)' fg=cyan
            '^(R|B)[[:space:]]' fg=cyan,bold
            '^(c|d|D|h|q|s|S)$' fg=cyan,bold
        )
    else
        _color=0
        ZSH_HIGHLIGHT_REGEXP=()
        print -n "\033]11;rgb:00/00/00\007" >&3
        
        [[ -z $2 ]] && red_mode 1 >&3
        print -n "\033]10;rgb:ff/df/df\007" >&3
    fi
}


# =========================== SETUP ========================== #

use_extra 0
reminder_file="/tmp/reminders_sorted.txt"
LC_ALL=C printf '%s\n' "$(ob "p/auto/ash remind" | awk NF)" | grep -vF "**" | sort > "$reminder_file"

unset HISTFILE SAVEHIST

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

color 1 no_shortcuts


# ========================= GENERAL FUNCTIONS ======================== #

function on_tab {
    clr
    divide "$start_time"
    a
}

# ======================== MAIN FUNCTION ======================= #

function a_ui {
    next_idx=$(py len)
    print_top_right
    echo "" > "$var_file_path"

    if ! command -v a.sh &>/dev/null; then
        echo "a.sh not found!"
        return
    fi

    while :; do
        [[ $_hist == 0 ]] && my_clear
        should_extra -c && use_extra 1 || use_extra 0

        take_input
        log_line "$line"

        # commands ------------------------------------------------------------------- #

        # Bin
        if [[ $line == 'B '* ]]; then
            _sign="×"
            continue
        # Clear with reset
        elif [[ $line == 'c' ]]; then
            py clear
            my_clear
            fc -p
            echo "" > "$var_file_path"
            
            py map set -k offline_start -v "0" 
            next_idx=0

            start_time="$(date +"%Y-%m-%d %H:%M:%S")"
            divide "$start_time"
            continue
        # Divide
        elif [[ $line == 'd' ]]; then
            divide
            continue
        # Divide and clear
        elif [[ $line == 'D' ]]; then
            clear
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
        # Run
        elif [[ $line == 'R '* ]]; then
            command=$(echo "$line" | sed -E 's/R[[:space:]]+//g')
            tmpfile=$(mktemp)
            
            eval "$command" >"$tmpfile"
            local output=$(<"$tmpfile")
            
            [[ -n $output ]] && echo -e "    \e[30m${output## }\e[0m"       
            rm "$tmpfile"
            continue
        # Silent for one command
        elif [[ $line == 's' ]]; then
            _silent=1
            continue
        # Toggle silent mode
        elif [[ $line == 'S' ]]; then
            if [[ $_silent == 2 ]]; then
                _silent=0
            else
                _silent=2
            fi
            continue
        fi

        # run -------------------------------------------------------- #

        expand_item "$line" expanded_line

        if [[ $expanded_line == [[:space:]]# ]]; then
            _sign="×"
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
            
            if [[ $_silent == 0 ]]; then
                [[ $speak == 1 ]] && my_speak "$expanded_line"
                handle_if_reminder "$line"
            elif [[ $_silent == 1 ]]; then
                _silent=0
            fi
        fi
    done
}


# ============================= HELPER FUNCTIONS ============================= #

function expand_item {
    local escaped=$(echo "$1" | sed -E \
        -e "s/'/\\'/g" \
        -e 's/`/\\`/g' \
        -e 's/"/\\"/g')

    local once_expanded_line=$(eval echo \"$escaped\")
    local expanded_line_loc=$(eval echo \"$once_expanded_line\" | tr -d '\\')

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

function handle_if_reminder {
    local input=$(echo ${1//[0-9.]##/*} | sed 's/#/TO /g' | sed 's/TO b t/t/g' | tr -d '\n')

    local dest=$(echo "$input" | grep -o 'TO [A-Za-z0-9_]\+' | tr -d '\n')
    if [[ -n $dest ]]; then
        _handle_if_reminder "$dest"
    fi

    _handle_if_reminder "$input"
}

function _handle_if_reminder {
    local reminders=$(look -f -- "- [ ] $1 |" "$reminder_file")
    while read -r reminder; do
        if [[ -n $reminder ]]; then
            local reminder_parts=("${(@s:|:)reminder}")
            local reminder_text="${reminder_parts[2, -1]## }"

            if [[ $reminder_text == "*"* ]]; then
                should_extra -C || continue

                rem=${reminder_text//'*'/}
                out "$rem"
            elif [[ $reminder_text == "\`"* ]]; then
                should_extra -c || continue

                cmd=${reminder_text//\`/}
                ttab -d '' -w $cmd
            else
                expanded=""
                expand_item "$reminder_text" expanded
                ( nohup a.sh "$expanded" &>/dev/null & )
            fi
        fi
    done <<< "$reminders"
}

function my_clear {
    printf "\033]1337;ClearScrollback\a" >&3
    
    local cols=$(tput cols)
    local wipe_col=$((cols - $max_pyg_preview))
    print -n "\e7\e[1;${wipe_col}H\033[35m${wiper}\033[0m\e8" >&3 

    ( print_top_right & )
}

function print_top_right {
    local row=1
    local cols=$(tput cols)
    local wipe_col=$((cols - $max_pyg_preview - 3))

    local old_offline_amt=$(py map get -k offline_amt -d 0)
    local offline_amt=$(cat "$HOME/.dotfiles/tmp/a.txt" | wc -l | tr -d '[:space:]')

    # offline info --------------------------------------------------------------- #

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

        print -n "\e7\e[${row};${wipe_col}H\033[35m${wiper}\033[0m\e8" >&3
        print -n "\e7\e[1;${col}H\033[33m${text}\033[0m\e8" >&3

        row=$((row + 1))
        py map set -k offline_amt -v "$offline_amt"
    fi

    # expansion info ------------------------------------------------------------- #

    if should_extra -C; then
        if [[ -n $pgo ]]; then
            print -n "\e7\e[${row};${wipe_col}H\033[35m${wiper}\033[0m\e8" >&3
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

    [[ $audio == 1 ]] && beep 0.55

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