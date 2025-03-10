#!/bin/zsh

function p {
    if [ "$1" = "-l" ]; then
        shift
        result=$(echo $my_playlist | grep -i "$*")
        result_amt=$(echo $result | wc -l | tr -d ' ')

        if [ $result_amt -gt 1 ]; then
            echo $result | awk '{printf "\033[0;31m%d -\033[0m %s\n", NR, $0}'
            echo -n "Pick index: "
            read index
            result=$(echo $result | sed -n "${index}p")
        else
            echo Found: "$result"
        fi

        if [ -n "$result" ]; then
            mpv --no-video --volume=60 --msg-level=all=error --loop "ytdl://ytsearch:$result" --screen-name="$*"
        else
            echo "Not found"
        fi

    else
        if [ "$*" = "podd" ]; then
            mpv --shuffle --no-video --volume=60 "$podd_url" --keep-open=always --screen-name=podd
        elif [ "$*" = "good" ]; then
            mpv --shuffle --no-video --volume=60 "$good_url" --keep-open=always --screen-name=good
        elif [ "$*" = "fish" ]; then
            "$HOME/.dotfiles/scripts/path/task/a.sh" $(tod) $fish 1 s
            mpv --no-video --volume=60 --loop "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/fish.mp3" --screen-name=fish
        elif [ "$*" = "brown" ]; then
            mpv --no-video --loop --msg-level=all=info --volume=65 "$HOME/Library/Mobile Documents/com~apple~CloudDocs/media/audio/brown_noise.mp3" --screen-name=brown
        elif [ "$*" = "ram" ]; then
            mpv --shuffle --no-video --volume=80 "$ram_url" --screen-name=ram
        elif [ "$*" = "work" ]; then
            mpv --shuffle --no-video --loop --volume=60 "https://www.youtube.com/playlist\?list\=PLAy7-c9usC7SusYkjodaoIyC24Yp8YjJ6" --screen-name=work
        else
            mpv --no-video --volume=60 --msg-level=ao/coreaudio=no --loop "ytdl://ytsearch:$*"
        fi
    fi
}
