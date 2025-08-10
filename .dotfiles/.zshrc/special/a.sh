#!/bin/zsh

tomp=" tom #run :p "
yd="yesterday"

# =========================== SETUP ========================== #

ZSH_HIGHLIGHT_REGEXP+=(
    '#[a-z0-9]+[a-zA-Z0-9]*' fg=green,bold
    '(?<=\s|^)p3(?=\s|$)' fg=magenta,underline
    '(\s|^)p1(\s|$)' fg=red,bold
    '\*\*.+\*\*' fg=red,bold
    '(?<!\*)\*[^*]+\*(?!\*)' fg=magenta,underline
    ';' fg=yellow,bold
    '@\w+' fg=blue
    '\$\([^\$]+\)' fg=cyan
)

unset ZSH_AUTOSUGGEST_STRATEGY
unset HISTFILE SAVEHIST

# ========================= GENERAL FUNCTIONS ======================== #

function on_tab {
    clr
    a
}

# ======================== A FUNCTIONS ======================= #

function a_ui {
    added_items_amt=0
    print_top_right "($added_items_amt)"

    while :; do
        m_vared

        # log ------------------------------------------------------------------------ #

        $MY_SCRIPTS/lang/shell/utils/log.sh -f a_raw "$line"

        # Add to history
        if [[ $line != ' '* ]]; then
            print -s -- "$line"
        fi

        # show number
        ((added_items_amt++))
        print_top_right "($added_items_amt)"

        # commands ------------------------------------------------------------------- #

        if [[ $line == 'c' ]]; then
            printf "\033]1337;ClearScrollback\a"
            added_items_amt=0
            print_top_right "($added_items_amt)"
            continue
        elif [[ $line == 'q' ]]; then
            echo "quit"
            return 0
        fi

        # escape characters ------------------------------------------ #

        local escaped=$(echo "$line" | sed -E \
            -e "s/'/\\'/g" \
            -e 's/`/\\`/g' \
            -e 's/"/\\"/g')
        local expanded_line=$(eval echo \"$escaped\" | tr -d '\\')

        if [[ "$expanded_line" == "$line" ]]; then
            did_expand_a=false
        else
            did_expand_a=true
        fi

        # run -------------------------------------------------------- #

        if command -v a.sh &>/dev/null; then
            (
                nohup a.sh "$expanded_line" &>/dev/null &
            )
        else
            echo "(ERR: a.sh not found)"
        fi
    done
}

# ============================= HELPER FUNCTIONS ============================= #

function print_top_right {
    local text="$1"
    local cols=$(tput cols)
    local col=$((cols - ${#text} + 1))
    print -n "\e7\e[1;${col}H${text}\e8"
}

function m_vared {
    line=""
    local offline_amt=$(cat "$HOME/.dotfiles/tmp/a.txt" | wc -l | tr -d '[:space:]')
    local sign="-"

    if [[ $did_expand_a == true ]]; then
        sign="!"
    fi

    if [[ $offline_amt != '0' ]]; then
        local padded_offline_amt=$(printf "%02d" $offline_amt)
        vared -p "%B%F{yellow}($padded_offline_amt) $sign%f%b " line
    else
        vared -p "%B%F{yellow}$sign%f%b " line
    fi

    line=$(echo "$line" | tr -d '\\')
}
