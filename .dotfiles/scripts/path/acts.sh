#!/bin/zsh

local_online_tools="$HOME/Developer/server-app"


function acts {
    print -n -u2 "\033[90mExcluding: "

    # calculate query ------------------------------------------------------------ #

    local query=$(echo "$*" | tr ' ' '/')

    if ! map.sh -s 'opt.no_calc'; then
        if in_window.sh $(map.sh 'routine.detach' 22:00) 00:00; then
            query="$query/eve"
            print -n -u2 "eve, "
        fi

        if map.sh -s 's.eye' && ! map.sh -s 'ps.off'; then
            query="$query/eye"
            print -n -u2 "eye, "
        fi

        if [[ $(map.sh 's.main') -ge 420 ]]; then
            query="$query/load"
            print -n -u2 "load, "
        fi 

        if map.sh -s 'ps.off'; then
            query="$query/off"
            print -n -u2 "off, "
        else
            query="$query/-off"
            print -n -u2 "-off, "
        fi
    else
        print -n -u2 "no_calc, "
    fi

    print -n -u2 "| "

    # run ------------------------------------------------------------------------ #

    local output=$(
        cd $local_online_tools/dist/routes/act
        NODE_NO_WARNINGS=1 DO_LOG=false node local.js "$query" || tl.sh "act/$query"
    )

    # general filters ---------------------------------------------------- #

    if ! map.sh -s opt.use_flashcards; then
        output=$(echo "$output" | grep -v 'flashcards^')
        print -n -u2 "flashcards, "
    fi

    if [[ $(obsi.sh 8 | wc -l) -lt 3 ]]; then
        output=$(echo "$output" | grep -v 'obsi^')
        print -n -u2 "obsi, "
    fi

    if ! map.sh -s 's.tv'; then
        output=$(echo "$output" | grep -v 'review_tv^')
        print -n -u2 "review_tv, "
    fi

    if map.sh -s 's.sick'; then
        output=$(echo "$output" | grep -v 'msg^')
        print -n -u2 "msg, "
    fi

    # done filters --------------------------------------------------------------- #

    if map.sh -s 'done.floss'; then
        output=$(echo "$output" | grep -v 'floss^')
        print -n -u2 "floss, "
    fi

    if map.sh -s 'done.gym'; then
        output=$(echo "$output" | grep -v 'gym^')
        print -n -u2 "gym, "
    fi

    # note filters --------------------------------------------------------------- #

    if [[ $output == *'exorita^'* ]] && ob.sh xord | grep -q "$(date +'%Y-%m-%d')"; then
        output=$(echo "$output" | grep -v 'exorita^')
        print -n -u2 "exorita, "
    fi

    if [[ $output == *'wash_face^'* ]] && ob.sh b | grep -q 'shower'; then
        output=$(echo "$output" | grep -v 'wash_face^')
        print -n -u2 "wash_face, "
    fi

    # Note length checks

    output=$(act_ob_filter 'b' 4 "$output")
    output=$(act_ob_filter 'plan' 3 "$output")
    output=$(act_ob_filter 'bdg' 4 "$output")
    output=$(act_ob_filter 'by' 6 "$output")
    output=$(act_ob_filter 'do' 4 "$output")
    output=$(act_ob_filter 'zz' 5 "$output")
    output=$(act_ob_filter 'ect' 7 "$output")

    # todoist filters ------------------------------------------------------------ #

    output=$(act_td_filter 'p1' 1 "$output")
    output=$(act_td_filter '#inbox' 20 "$output")
    output=$(act_td_filter '#u' 20 "$output")
    output=$(act_td_filter '@eval' 4 "$output")
    output=$(act_td_filter '@res' 7 "$output")

    # routine filters ----------------------------------------------------------- #

    if in_window.sh $(map.sh routine.detach 21:00) '4:00'; then

        if in_window.sh $(map.sh routine.full_detach 22:00) '4:00'; then
            output=$(echo "$output" | grep -v 'cook^' | grep -v 'by^' | grep -v 'walk^')
            print -n -u2 "cook, by, walk, "

            if in_window.sh $(map.sh routine.bedtime 22:30) '4:00'; then
                output=$(echo "$output" | grep -v 'floss^')
                print -n -u2 "floss, "
            fi
        fi
    fi

    # big filters ----------------------------------------------------------------- #

    if [[ " $@ " == *" b "* ]]; then
        ob.sh b | while read -r break_item; do
            local item=$(echo "$break_item" | grep -oE '[[:alnum:]_]([[:alnum:]_]| )+$')

            if [[ -z "$item" ]]; then
                continue
            fi

            if printf "%s\n" "$output" | grep -qF "$item"; then
                print -n -u2 "$item, "
                output=$(echo "$output" | grep -v "$item")
            fi
        done
    fi

    # print ------------------------------------------------------ #

    print -u2 "\033[0m"
    echo $output | "$HOME/.dotfiles/scripts/secret/act_highlight.sh"

    # sync ----------------------------------------------------------------------- #

    if "$MY_SCRIPTS/lang/shell/rand.sh" 3 >/dev/null; then
        act_sync &
    fi
}


function act_sync {
    local table=$(curl -s --connect-timeout 2 "$MY_CONFIG_URL/server-app/act.tsv")

    if [ -n "$table" ]; then
        echo "$table" >$local_online_tools/data/act.tsv
        print -u2 "Updated act.tsv"
    else
        print -u2 "Failed to update act.tsv"
    fi
}


function act_td_filter {
    # Speeds up checks
    if ! echo "$3" | grep -q "$1^"; then
        echo "$3"
        return    
    fi

    if [[ $(tdl.sh -F '@run' "$1" | wc -l) -lt $2 ]]; then
        echo "$3" | grep -v "$1^"
        print -n -u2 "$1, "
    else
        echo "$3"
    fi
}


function act_ob_filter {
    local note_path="$1"
    local min_length="$2"
    local output="$3"

    if [[ $output == *"$note_path^"* && $(ob.sh "$note_path" | grep -E -v '##|^$|---' | wc -l) -lt $min_length ]] then
        echo "$output" | grep -v "$note_path^"
        print -n -u2 "$note_path, "
    else
        echo "$output"
    fi 
}

acts "$*"