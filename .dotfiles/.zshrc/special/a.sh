#!/bin/zsh

sign="-"

# ================================= CONSTANTS ================================ #

reminder_text=$(ob "p/auto/ash remind")
init_cols=$(tput cols)

p=">-1"
pp=">-1p"
pd=">-1d"

tomp=" tom #run :p "
tomb=" tom #run :b "
yd="yesterday"

# =============================== USER FEATURES ============================== #

alias pyg="py get --"

function py {
    python3 "$MY_SCRIPTS/lang/python/a.py" "$@"
}


function len {
    say $(py len)
}


function comp {
    if [[ $1 == '1' ]] || [[ -z $1 && -z $ZSH_AUTOSUGGEST_STRATEGY ]]; then
        ZSH_AUTOSUGGEST_STRATEGY=(history)
    else
        unset ZSH_AUTOSUGGEST_STRATEGY
    fi
}


function hist {
    comp $1

    if [[ $1 == '1' ]] || [[ -z $1 && $blank == 1 ]]; then
        blank=0
        my_clear
        divide
    else
        speak=0
        blank=1
    fi
}


function help {
    echo "options - blank | speak"
    echo "accessable - start_time \n"

    cat <<< "functions:
    - comp 1/0 - turn on or off completions 
    - hist 1/0 - turn on or off history (comp, speak, blank)
    - len - get length of history
    - py <args> - run python script a.py with args
    - help"
}


# OPTIONS

blank=0
speak=0

# ACCESSABLE

start_time="$(date +"%Y-%m-%d %H:%M:%S")"

# =========================== SETUP ========================== #

ZSH_HIGHLIGHT_REGEXP+=(
    '#[a-z0-9]+[a-zA-Z0-9]*' fg=green,bold
    ';' fg=yellow,bold
    '@\w+' fg=blue

    '(\s|^)p1(\s|$)' fg=red,bold
    '(\s|^)p2(\s|$)' fg=red,bold
    '\*\*.+\*\*' fg=red,bold

    '(?<=\s|^)p3(?=\s|$)' fg=magenta,underline
    '(?<!\*)\*[^*]+\*(?!\*)' fg=magenta,underline

    '\$\([^\$]+\)' fg=cyan
    '(?<=^|\s)>(-?\d|\w)+(?=$|\s)' fg=cyan,bold
    '^RUN[[:space:]]' fg=cyan,bold
)

unset HISTFILE SAVEHIST

cmds=(
  "RUN blank="
  "RUN comp"
  "RUN exec zsh"
  'RUN echo $start_time'
  "RUN help"
  '$pp'
  '$pd'
  '$p'
  "RUN pyg"
  "RUN py"
  "RUN len"
  "null"
  "RUN speak="
  "RUN hist"
  ">-1"
)

for cmd in "${cmds[@]}"; do
  print -s -- "$cmd"
done


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
            if [[ $line != *'#'* ]]; then 
                print -s -- "$line"
                print -s -- " "
            fi
        fi

        # commands ------------------------------------------------------------------- #

        if [[ $line == 'c' ]]; then
            py clear
            my_clear
            
            py map set -k offline_start -v "0" 
            next_idx=0

            start_time="$(date +"%Y-%m-%d %H:%M:%S")"
            divide "$start_time"
            continue
        elif [[ $line == 'RUN'* ]]; then
            command=$(echo "$line" | sed -E 's/RUN[[:space:]]+//g')
            local output=$(eval "$command")
            [[ -n $output ]] && echo " 🖨️ $output"
            continue
        elif [[ $line == 'd' ]]; then
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
        local expanded_line=$(eval echo \"$escaped\" | tr -d '\\')

        if [[ $expanded_line =~ '(?<=^|\s)>((-?\d|\w)+)(?=$|\s)' ]]; then
            replacement=$(py get -- "$match[1]")
            local part_to_replace=">${match[1]}"
            
            expanded_line=$(py replace "$expanded_line" "$part_to_replace" "$replacement")
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
            print_if_reminder
        fi
    done
}


# ============================= HELPER FUNCTIONS ============================= #


function print_if_reminder {
    if reminder=$(echo "- [ ] $reminder_text |" | grep -m1 -F -- "$expanded_line"); then
        reminder_parts=("${(@s:|:)reminder}")
        echo " 🔔 ${reminder_parts[2]## }"
    fi
}


function divide {
    local time="$1"
    [[ -z $time ]] && time="$(date +"%Y-%m-%d %H:%M:%S")"
    local text=" $time "
    
    echo -n '\033[33m'
    printf '%*s' $(( init_cols / 2 - ${#text} / 2)) '' | tr ' ' '-'
    printf '%s' "$text"
    echo '\033[0m'
}


function my_clear {
    printf "\033]1337;ClearScrollback\a"
    print_top_right
}


function print_top_right {
    local old_offline_amt=$(py map get -k offline_amt -d 0)
    local offline_amt=$(cat "$HOME/.dotfiles/tmp/a.txt" | wc -l | tr -d '[:space:]')

    [[ $old_offline_amt -eq 0 && $offline_amt -eq 0 ]] && return
    
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
    local cols=$(tput cols)
    local col=$((cols -  $((${#text})) + 1))
    print -n "\e7\e[1;${col}H\033[33m${text}\033[0m\e8"

    py map set -k offline_amt -v "$offline_amt"
}


function m_vared {
    local padded_num=$(printf "%02d" $next_idx)

    line=""
    vared -p "%B%F{yellow}$padded_num $sign%f%b " line

    line=$(echo "$line" | tr -d '\\')
    sign="-"
}
