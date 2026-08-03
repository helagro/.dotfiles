#!/bin/zsh


function on_tab {
    act_ui
}


function act_ui {
    local input

    ZSH_HIGHLIGHT_REGEXP+=(
        '-\w+' fg=red
        '".*"' fg=green
        "'.*'" fg=green  
    )

    while :; do
        vared -p '%B%F{yellow}>%f%b ' -c input
        [[ -z $input ]] && break

        eval "run_act $input"
        echo

        print -s -- "$input"
        print -s -- " "
    done
}


function run_act {
    
    # handle day ----------------------------------------------------------------- #

    local start_day=$(date +%-d)
    if [[ $start_day != $(map -m act.start_day) ]]; then
        printf "\033]1337;ClearScrollback\a"
        echo "> $*" | to_color.sh yellow
        map -m set act.start_day "$start_day"
    fi

    # handle already running ----------------------------------------------------- #

    if map.sh -m -s act.running; then
        echo "[WARN] - Act is already running" | to_color.sh red
    fi

    # run ------------------------------------------------------------------------ #

    act "$@"

    # break reminder ------------------------------------------------------------- #

    { 
        if [[ $activity_name == "main" ]] && is_home --guess-yes; then
            if map.sh -s s.blank; then
                echo "silence meditation"
            else
                echo $reminder_1
            fi
        fi 
    } | to_color.sh green
}

