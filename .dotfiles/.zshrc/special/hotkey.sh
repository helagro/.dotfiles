#!/bin/zsh

loc_files_url="http://$LOCAL_SERVER_IP:8004/files"
background_vol=50
foreground_vol=60

# ================================= FUNCTIONS ================================ #

function on_tab {
    clear
}


function p {
    local do_local=false
    if [[ $1 == 'lc' || $1 == 'loc' ]]; then
        do_local=true
        shift
    fi

    local media="$1"
    if [[ $# -gt 0 ]]; then
        shift
    fi

    if $do_local; then
        if [[ -z $media || $media == *"/" ]]; then
            curl -sS "$loc_files_url/$media" | rat.sh -p -l json
            return
        fi

        if curl -sI -o /dev/null -w '%{http_code}\n' "$loc_files_url/$media" | grep -q '^200$'; then
            my_play "$loc_files_url/$media" "$@" --loop
        elif curl -sI -o /dev/null -w '%{http_code}\n' "$loc_files_url/$media.mp3" | grep -q '^200$'; then
            my_play "$loc_files_url/$media.mp3" "$@" --loop
        elif curl -sI -o /dev/null -w '%{http_code}\n' "$loc_files_url/audio/$media.mp3" | grep -q '^200$'; then
            my_play "$loc_files_url/audio/$media.mp3" "$@" --loop
        else
            echo "File not found: $media" | to_color.sh red >&2
        fi
        
    elif [[ $media == "clue" ]]; then
        play_clue "$@"

    elif [ "$media" = "ambiance" ]; then
        my_play "https://youtu.be/_4kHxtiuML0"

    elif [ "$media" = "breath" ]; then
        my_play -l "https://youtu.be/Za4gLn2KoHM"

    elif [[ "$media" == "exist" ]]; then
        if rand 2 >/dev/null; then
            my_play "$ram_url"
        else
            my_play "$ram_url_2"
        fi
    
    elif [[ "$media" == "work" ]]; then
        my_play "$work_url" --loop

    else
        play_unproductive "$media" "$@"
    fi
}

function play_clue {
    local current last_current

    trap "ps -ef | grep -- '--screen-name=clue' | awk '{print \$2}' | xargs kill 2>/dev/null; return 1" INT

    while :; do
        last_current="$current"
        current=$(map.sh -m act.current)

        if [[ "$current" == "$last_current" ]]; then
            sleep 10
            continue
        fi
        
        ps -ef | grep -- '--screen-name=clue' | awk '{print $2}' | xargs kill 2>/dev/null
        [[ $current == "null" ]] && continue

        if [[ $current =~ "improve|fix" ]]; then
            p pink --screen-name=clue &
        elif [[ $current =~ "p1|study" ]]; then
            p brown --screen-name=clue &
        # TODO - reflect → Soft rain / light nature ambience
        
        elif [[ $current == "sys" ]]; then
            p 'plane' --screen-name=clue &
        fi
    done
}
