#!/bin/zsh

loc_files_url="http://$LOCAL_SERVER_IP:8004/files"
background_vol=45
foreground_vol=60


function on_tab {
    clear
}

function p {
    local media=$1
    shift

    _play_opts=(--shuffle --no-video --demuxer-max-bytes=50MiB --screen-name="$media")

    # productive ----------------------------------------------------------------- #

    if [ "$media" = "breath" ]; then
        mpv "${_play_opts[@]}" --volume=$foreground_vol "https://youtu.be/Za4gLn2KoHM" --screen-name=breath

    elif [ "$media" = "ram" ]; then
        mpv "${_play_opts[@]}" "$ram_url" --screen-name=ram

    elif [ "$media" = "work" ]; then
        mpv "${_play_opts[@]}" \
            --loop \
            --volume=$background_vol \
            "$work_url" 
    elif (! map.sh -s 's.drown') && is_home; then
        echo "Missing tag"
        return 1
    fi

    # local media files ---------------------------------------------------------- #

    local media_folder="$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/tools"
    if [[ -f "$media_folder/$media.mp3" ]]; then 
        _p_file "$media_folder/$media.mp3" "$@"
        return
    elif [[ "$media" == "ls" || "$media" == "list" ]]; then
        ls "$media_folder"
        return
    fi

    # custom playlists ----------------------------------------------------------- #

    if [ "$media" = "podd" ]; then
        if curl --connect-timeout 1 -s "$LOCAL_SERVER_IP:8004" >/dev/null; then
            leverage

            while [[ $? -eq 0 ]]; do
                local podd_path=$(curl -sS "$loc_files_url/rand-path/podd")
                mpv "${_play_opts[@]}" \
                    --volume=$background_vol "$podd_path" \
                    "$@"
                # "$HOME/.dotfiles/scripts/path/task/a.sh" "$(day) podd 60"
            done
        else
            if rand 2 >/dev/null; then
                mpv "${_play_opts[@]}" --volume=$background_vol "$podd_url" "$@"
            else
                mpv "${_play_opts[@]}" --volume=$background_vol "$podd_url_2" "$@"
            fi
        fi

    # youtube playlists ---------------------------------------------------------- #

    elif [ "$media" = "good" ]; then
        if [[ -d $good_path ]]; then
            mpv "${_play_opts[@]}" --volume=$background_vol "$good_path" "$@"
        else
            mpv "${_play_opts[@]}" --volume=$background_vol "$good_url" "$@"
        fi

    elif [ "$media" = "interest" ]; then
        leverage
        mpv "${_play_opts[@]}" --volume=$background_vol "$interesting" "$@"


    # youtube search ------------------------------------------------------------- #

    else
        mpv "${_play_opts[@]}" --volume=$foreground_vol --msg-level=ao/coreaudio=no --loop "ytdl://ytsearch:$media $*"
    fi
}

function _p_file {
    local media_file=$1
    local volume=$foreground_vol
    shift

    if [[ "$media_file" == *"fish.mp3" ]]; then
        volume=$background_vol
    elif [[ "$media_file" == *"pmr.mp3" ]]; then
        "$HOME/.dotfiles/scripts/path/task/a.sh" $(day) mindwork 5
    fi

    mpv "${_play_opts[@]}" \
        --volume=$volume \
        --loop \
        "$media_file" \
        "$@"
}
