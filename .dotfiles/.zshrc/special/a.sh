#!/bin/zsh

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
    m_vared

    # Ask for lines until 'q' is entered
    while [[ $line != 'q' ]]; do

        # log ------------------------------------------------------------------------ #

        $MY_SCRIPTS/lang/shell/utils/log.sh -f a_raw "$line"

        # Add to history
        if [[ $line != ' '* ]]; then
            print -s -- "$line"
        fi

        # commands ------------------------------------------------------------------- #

        # identify
        if [[ $line == 'i' ]]; then
            (afplay $HOME/.dotfiles/assets/audio/brown_noise.mp3 &)

            printf "\033[41m"
            clear
            sleep 0.5
            printf "\033[0m"
            clear
            line=""
            continue
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
        m_vared
    done

    echo "quit"
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
