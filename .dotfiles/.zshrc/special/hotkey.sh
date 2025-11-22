#!/bin/zsh

background_vol=45
foreground_vol=60


function on_tab {
    clear
}

function p {
    local media=$1
    shift

    opts=(--shuffle --no-video --demuxer-max-bytes=30MiB --screen-name="$media")

    if [ "$media" = "podd" ]; then

        if curl --connect-timeout 1 -s "$LOCAL_SERVER_IP:8004" >/dev/null; then
            while [[ $? -eq 0 ]]; do
                mpv "${opts[@]}" \
                    --volume=$background_vol "http://$LOCAL_SERVER_IP:8004/files/rand/podd" \
                    "$@"
                "$HOME/.dotfiles/scripts/path/task/a.sh" "$(day) podd 60"
            done
        else
            if rand 2 >/dev/null; then
                mpv "${opts[@]}" --volume=$background_vol "$podd_url" "$@"
            else
                mpv "${opts[@]}" --volume=$background_vol "$podd_url_2" "$@"
            fi
        fi

    elif [ "$media" = "good" ]; then
        if [[ -d $good_path ]]; then
            mpv "${opts[@]}" --volume=$background_vol "$good_path" "$@"
        else
            mpv "${opts[@]}" --volume=$background_vol "$good_url" "$@"
        fi
    elif [ "$media" = "interest" ]; then
        mpv "${opts[@]}" --volume=$background_vol "$interesting" "$@"
    elif [ "$media" = "fish" ]; then
        # "$HOME/.dotfiles/scripts/path/task/a.sh" $(tod) $fish 1 s
        mpv "${opts[@]}" \
            --volume=$background_vol \
            --loop "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/fish.mp3" \
            "$@"
    elif [ "$media" = "noise" ]; then
        mpv "${opts[@]}" \
            --loop \
            --msg-level=all=info \
            --volume=$foreground_vol \
            "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/brown_noise.mp3"
    elif [ "$media" = "pmr" ]; then
        "$HOME/.dotfiles/scripts/path/task/a.sh" $(day) mindwork 5
        mpv "${opts[@]}" \
            --volume=$foreground_vol \
            "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/pmr-shortened.mp3" 
    elif [ "$media" = "ram" ]; then
        mpv "${opts[@]}" "$ram_url" --screen-name=ram
    elif [ "$media" = "breath" ]; then
        if [[ -f "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/breath.mp3" ]]; then
            mpv "${opts[@]}" \
                --volume=$foreground_vol \
                "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/breath.mp3"
        else
            # Fallback
            mpv "${opts[@]}" --volume=$foreground_vol "https://youtu.be/Za4gLn2KoHM" --screen-name=breath
        fi
    elif [ "$media" = "work" ]; then
        mpv "${opts[@]}" \
            --loop \
            --volume=$background_vol \
            'https://youtube.com/playlist?list=PLAy7-c9usC7SusYkjodaoIyC24Yp8YjJ6&si=lYZsiknp00HECD2W'
    else
        mpv "${opts[@]}" --volume=$foreground_vol --msg-level=ao/coreaudio=no --loop "ytdl://ytsearch:$media $*"
    fi
}
