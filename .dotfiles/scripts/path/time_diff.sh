set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

positive_only=false
return_minutes=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
        printf "Usage: time_diff [options...] <time1> <time2>\n"
        printf " %-3s %-20s %s\n" "-h" "--help" "Show this help message"
        printf " %-3s %-20s %s\n" "-p" "" "Only allow positive differences"
        return 0
        ;;
    -p)
        positive_only=true
        shift
        ;;
    -m)
        return_minutes=true
        shift
        ;;
    *)
        break
        ;;
    esac
done

seconds1=$(date -j -f "%H:%M" "$2" +"%s" 2>/dev/null)
seconds2=$(date -j -f "%H:%M" "$1" +"%s" 2>/dev/null)
diff=$((seconds1 - seconds2))

if [ $diff -lt 0 ]; then
    if $positive_only; then
        exit 1
    else
        diff=$((diff + 86400))
    fi
fi

if $return_minutes; then
    echo $((diff / 60))
else
    printf "%02d:%02d\n" $((diff / 3600)) $(((diff % 3600) / 60))
fi
