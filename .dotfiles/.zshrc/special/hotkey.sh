#!/bin/zsh

loc_files_url="http://$LOCAL_SERVER_IP:8004/files"
background_vol=45
foreground_vol=60

# ================================= FUNCTIONS ================================ #

function on_tab {
    clear
}


function p {
    local media="$1"
    shift

    if [ "$media" = "breath" ]; then
        my_play -l "https://youtu.be/Za4gLn2KoHM"
        return

    elif [ "$media" = "ambiance" ]; then
        my_play "https://youtu.be/_4kHxtiuML0"
        return

    elif [[ $media == "ambiance2" ]]; then
        my_play "$loc_files_url/ambiance2.mp3"
        return

    elif [ "$media" = "ram" ]; then
        my_play "$ram_url"
        return
    
    elif [ "$media" = "work" ]; then
        my_play "$work_url" --loop
        return

    else
        play_unproductive "$media" "$@"
    fi

}
