function in_window {
    local now=$(date +"%H:%M")

    before $1 $now && before $now $2
}

function before {
    time_diff.sh -p $1 $2 >/dev/null
}

in_window "$@"