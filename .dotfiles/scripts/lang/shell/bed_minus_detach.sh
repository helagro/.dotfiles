detach_time=$(map.sh routine.detach)
if [ $? -ne 0 ] || [ -z "$detach_time" ]; then
    echo "No detach_time" | to_color.sh red >&2
    exit 1
fi

bed_time=$(map.sh routine.bed_time)
if [ $? -ne 0 ] || [ -z "$bed_time" ]; then
    echo "No bed_time" | to_color.sh red >&2
    exit 1
fi

time=$(time_diff.sh $detach_time $bed_time)

hours=${time%%:*}
minutes=${time#*:}
echo $((hours * 60 + minutes))