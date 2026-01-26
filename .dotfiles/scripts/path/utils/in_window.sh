function in_window {
    local start=$1
    local end=$2
    local now=$(date +"%H:%M")

    if before "$start" "$end"; then
        # Same-day window
        before "$start" "$now" && before "$now" "$end"
    else
        # Overnight window (crosses midnight)
        before "$start" "$now" || before "$now" "$end"
    fi
}

function before {
    time_diff.sh -p $1 $2 >/dev/null
}

in_window "$@"