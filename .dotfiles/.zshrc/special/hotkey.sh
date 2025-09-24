#!/bin/zsh

vol=60

function on_tab {
    clear
}

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
    elif [ "$*" = "pmr" ]; then
        "$HOME/.dotfiles/scripts/path/task/a.sh" $(day) mindwork 5
        mpv --no-video --volume=$vol "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/pmr-shortened.mp3" --screen-name=pmr
    elif [ "$*" = "ram" ]; then
        mpv --shuffle --no-video "$ram_url" --screen-name=ram
    elif [ "$*" = "breath" ]; then
        "$HOME/.dotfiles/scripts/path/task/a.sh" $(day) mindwork 8

        if [[ -f "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/breath.mp3" ]]; then
            mpv --no-video --volume=$vol "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/breath.mp3" --screen-name=breath
        else
            # Fallback
            mpv --no-video --volume=$vol "https://youtu.be/Za4gLn2KoHM" --screen-name=breath
        fi
    elif [ "$*" = "work" ]; then
        mpv --shuffle --no-video --loop --volume=$vol 'https://youtube.com/playlist?list=PLAy7-c9usC7SusYkjodaoIyC24Yp8YjJ6&si=lYZsiknp00HECD2W' --screen-name=work
    else
        mpv --no-video --volume=$vol --msg-level=ao/coreaudio=no --loop "ytdl://ytsearch:$*"
    fi
}
