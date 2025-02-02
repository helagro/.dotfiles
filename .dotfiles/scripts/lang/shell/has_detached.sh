now=$(date +%H:%M)
if time_diff.sh -p "20:00" $now >/dev/null; then
    detach="$(tl.sh 'routines/detach/start?sep=%3A')"
    # NOTE - Defaults to has detached IF can't reach endpoint
    if [ -z "$detach" ] || time_diff.sh -p "$detach" $now >/dev/null; then
        exit 0
    fi
fi

exit 1
