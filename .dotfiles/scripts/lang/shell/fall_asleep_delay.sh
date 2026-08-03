
bedtime=$(map.sh routine.bed_time 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$bedtime" ]; then
    echo "No bed_time" | to_color.sh red >&2
    exit 1
fi

if [[ -n $1 ]]; then
    # Perminant debug option
    sleep_start="$1"
else
    sleep_start=$(is.sh -v sleep_start 1 | python3 $MY_SCRIPTS/lang/python/hm.py | sed 's/"//g' 2>/dev/null)
fi

if [ $? -ne 0 ] || [ -z "$sleep_start" ] || [[ $sleep_start == "null" ]]; then
    exit 1
fi

# Converts to 24-hour format from starting at 12:00 (but not normal 12h clock!)
sleep_start=$(time_diff.sh "12:00" "$sleep_start")

# echo "Sleep start: $sleep_start"
# echo "Bedtime: $bedtime"
time=$(time_diff.sh $bedtime $sleep_start)
if time_diff.sh -p "12:00" "$time" >/dev/null; then
    exit 1
fi

hours=${time%%:*}
minutes=${time#*:}
sleep_delay=$((hours * 60 + minutes))
if [[ $sleep_delay -lt 0 ]]; then
    exit 1
fi

echo $sleep_delay