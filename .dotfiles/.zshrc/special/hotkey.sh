#!/bin/zsh

background_vol=45
foreground_vol=60

opts=(--shuffle --no-video --demuxer-max-bytes=30MiB)

function on_tab {
    clear
}

function p {
    if [ "$*" = "podd" ]; then

        if curl --connect-timeout 1 -s "$LOCAL_SERVER_IP:8004" >/dev/null; then
            while [[ $? -eq 0 ]]; do
                mpv "${opts[@]}" --volume=$background_vol "http://$LOCAL_SERVER_IP:8004/files/rand/podd" --screen-name=podd
            done
        else
            if rand 2 >/dev/null; then
                mpv "${opts[@]}" --volume=$background_vol "$podd_url" --screen-name=podd
            else
                mpv "${opts[@]}" --volume=$background_vol "$podd_url_2" --screen-name=podd
            fi
        fi

    elif [ "$*" = "good" ]; then
        if [[ -d $good_path ]]; then
            mpv "${opts[@]}" --volume=$background_vol "$good_path" --screen-name=good
        else
            mpv "${opts[@]}" --volume=$background_vol "$good_url" --screen-name=good
        fi
    elif [ "$*" = "interest" ]; then
        mpv "${opts[@]}" --volume=$background_vol "$interesting" --screen-name=interest
    elif [ "$*" = "fish" ]; then
        # "$HOME/.dotfiles/scripts/path/task/a.sh" $(tod) $fish 1 s
        mpv "${opts[@]}" --volume=$background_vol --loop "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/fish.mp3" --screen-name=fish
    elif [ "$*" = "brown" ]; then
        mpv "${opts[@]}" --loop --msg-level=all=info --volume=$foreground_vol "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/brown_noise.mp3" --screen-name=brown
    elif [ "$*" = "pmr" ]; then
        "$HOME/.dotfiles/scripts/path/task/a.sh" $(day) mindwork 5
        mpv "${opts[@]}" --volume=$foreground_vol "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/pmr-shortened.mp3" --screen-name=pmr
    elif [ "$*" = "ram" ]; then
        mpv "${opts[@]}" "$ram_url" --screen-name=ram
    elif [ "$*" = "breath" ]; then
        if [[ -f "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/breath.mp3" ]]; then
            mpv "${opts[@]}" --volume=$foreground_vol "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/breath.mp3" --screen-name=breath
        else
            # Fallback
            mpv "${opts[@]}" --volume=$foreground_vol "https://youtu.be/Za4gLn2KoHM" --screen-name=breath
        fi
    elif [ "$*" = "work" ]; then
        mpv "${opts[@]}" --loop --volume=$background_vol 'https://youtube.com/playlist?list=PLAy7-c9usC7SusYkjodaoIyC24Yp8YjJ6&si=lYZsiknp00HECD2W' --screen-name=work
    else
        mpv "${opts[@]}" --volume=$foreground_vol --msg-level=ao/coreaudio=no --loop "ytdl://ytsearch:$*"
    fi
}
