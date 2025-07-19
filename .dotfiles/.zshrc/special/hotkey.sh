#!/bin/zsh

vol=60

function p {
    if [ "$*" = "podd" ]; then
        if rand 2 >/dev/null; then
            mpv --shuffle --no-video --volume=$vol "$podd_url" --keep-open=always --screen-name=podd
        else
            mpv --shuffle --no-video --volume=$vol "$podd_url_2" --keep-open=always --screen-name=podd
        fi

    elif [ "$*" = "good" ]; then
        mpv --shuffle --no-video --volume=$vol "$good_url" --keep-open=always --screen-name=good
    elif [ "$*" = "fish" ]; then
        # "$HOME/.dotfiles/scripts/path/task/a.sh" $(tod) $fish 1 s
        mpv --no-video --volume=$vol --loop "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/fish.mp3" --screen-name=fish
    elif [ "$*" = "brown" ]; then
        mpv --no-video --loop --msg-level=all=info --volume=65 "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/brown_noise.mp3" --screen-name=brown
    elif [ "$*" = "ram" ]; then
        mpv --shuffle --no-video --volume=80 "$ram_url" --screen-name=ram
    elif [ "$*" = "work" ]; then
        mpv --shuffle --no-video --loop --volume=$vol 'https://youtube.com/playlist?list=PLAy7-c9usC7SusYkjodaoIyC24Yp8YjJ6&si=lYZsiknp00HECD2W' --screen-name=work
    else
        mpv --no-video --volume=$vol --msg-level=ao/coreaudio=no --loop "ytdl://ytsearch:$*"
    fi
}
