function dawn {
    wifi on

    local focus_mode="off"
    local theme=0
    local night_shift=0

    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --focus)
            focus_mode="$2"
            shift 2
            ;;
        -t | --theme)
            theme="$2"
            shift 2
            ;;
        -n | --night)
            night_shift=1
            shift
            ;;
        -h | --help)
            echo "Usage: dawn [-f <focus_mode>] [-t <theme>] -n (night shift)"
            return 0
            ;;
        *)
            echo "Unknown option: $1"
            return 1
            ;;
        esac
    done

    # sync ------------------------------------------------------- #

    while ! ping -c 1 -t 1 8.8.8.8 &>/dev/null; do
        sleep 0.5
        echo "(waiting for internet...)"
    done

    td s

    # async ------------------------------------------------------ #

    (
        # NOTE - Needs to run early to complete before "later"
        (state_calc && dawn_state) &
        (
            local brightness=$(calc_brightness)
            if [[ -n "$brightness" && "$brightness" -ge 400 ]]; then
                echo "Brightness: $brightness"
            fi
        ) &
    )

    # env -------------------------------------------------------- #

    short -s focus "$focus_mode"
    short -s night_shift "$night_shift"
    theme $theme

    # display ---------------------------------------------------- #

    # Display main stuff
    $HOME/.dotfiles/scripts/lang/shell/task/run_task_sys.sh | to_color.sh cyan
    short day tod | to_color.sh blue

    ob dawn

    # Display secondary stuff
    tl.sh habits/streaks
    for state in "${state_list[@]}"; do
        $(eval echo \$$state) && echo $state
    done
    state.sh | jq -r 'to_entries[] | select(.value == true) | .key' | to_color.sh magenta

    local forecast=$(weather -l 1)
    if echo $forecast | grep -q "rain"; then
        echo "$forecast"
    fi

    wait
    later
    echo

    if [[ $(ob rule | lines) -gt 0 ]]; then
        ob rule
    fi
    if [[ $(ob p | lines) -gt 0 ]]; then
        ob p
    fi
    if [[ $(ob risk | lines) -gt 0 ]]; then
        ob risk
    fi
    if [[ $(b.sh | lines) -le 4 ]]; then
        a "#b train neck"
    fi

    tdi

    local cal=$(short day tod)
    if echo $cal | grep -Fq "climb"; then
        a "climb 1 s #u"
        ob fys
    fi

    # lastly ----------------------------------------------------- #

    a "dawn #u"
}

function dinner {
    local temp=$(sens -n temp)
    if [[ $temp -gt $dinner_temp_threshold ]]; then
        echo "Turn off radiator - ( $temp°C > $dinner_temp_threshold°C )"
    fi

    local did_creatine=$(tl.sh habits | jq '.creatine')
    if ! $did_creatine; then
        echo "Creatine - ( not taken )"
    fi

    # Track time
    local time_diff=$(bed_minus_dinner)
    [ -n "$time_diff" ] && a "bed_minus_dinner $time_diff s #u" && echo "tracked bed_minus_dinner AS $time_diff"

    echo
    ob dinner
}

function eve {
    local main screen
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    if $MY_SCRIPTS/lang/shell/is_help.sh $*; then
        print 'Usage: eve [options...]'
        printf " %-3s %-20s %s\n" "-F," "" "Skip enabling flight mode on phone"
        printf " %-3s %-20s %s\n" "-E," "" "Skip environment setup"
        printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
        return 0
    fi

    tg stop

    # Reset
    echo "" >$VAULT/p/risk.md
    echo "" >$VAULT/p/p.md
    echo "" >$VAULT/p/rule.md

    # other info ------------------------------------------------- #

    # Display Tasks
    day tom
    echo

    # Display weather if snow
    local forecast=$(weather)
    if echo $forecast | grep -q "snow"; then
        echo "$forecast"
    fi

    tl.sh habits

    echo "Temp: $(sens temp)°C"

    if [[ $(sens temp) -ge 22 ]]; then
        echo "Cool down"
    fi

    echo

    # manual track ------------------------------------------------- #

    echo "https://track.toggl.com/timer"

    vared -p "Main: " -c main
    a "main $(hm $main) s #u"

    vared -p "Screen: " -c screen
    a "screen $(hm $screen) s #u"

    # display main ----------------------------------------------- #

    # Show note
    ob eve

    # Show charge
    $HOME/.dotfiles/scripts/lang/shell/battery.sh 50

    # State conditionals
    ob "p/auto/state eve act.md" | state_switch.sh

    b.sh

    # environment ------------------------------------------------ #

    if [[ ! " $@ " == *" -E "* ]]; then
        short focus sleep
        short night_shift 1
        theme 1
    fi

    # auto track ------------------------------------------------- #

    a "eve #u"
    a "p_ett $(tdis | lines) s #u"
    short track_away

    # Track sleep delay
    local sleep_delay=$(fall_asleep_delay)
    if [ -n "$sleep_delay" ]; then
        a "$(in_days -1) sleep_delay $sleep_delay s #u"
    fi

    # Track bedtime minus detach
    local bed_minus_detach=$(bed_minus_detach)
    if [ -n "$bed_minus_detach" ]; then
        a "$(tod) bed_minus_detach $bed_minus_detach s #u"
    fi

    local brightness=$(calc_brightness)
    if [ -n "$brightness" ]; then
        a "$(tod) brightness $brightness s #u"
    fi

    # auto del --------------------------------------------------- #

    # Deletes tasks tagged @rm. NOTE - Has safeties and redundancies
    local del_tasks=$(tdls '@rm' -pF 'p1' | grep '@rm' | head -n 10)
    $MY_SCRIPTS/lang/shell/utils/log.sh -f eve "$del_tasks"
    local del_ids=$(echo -n "$del_tasks" | grep -o '^[0-9]*' | tr -s '[:space:]' ' ')

    if tdc $del_ids; then
        echo "Auto-deleted $(echo -n "$del_ids" | wc -w | tr -d '[:space:]') task(s)"
    else
        echo 'Auto task deletion failed'
    fi

    # flight mode ------------------------------------------------ #

    if [[ ! " $@ " == *" -F "* ]]; then
        echo "Waiting for phone to probably set DND..."
        sleep 9
        short phondo "flight mode"
    fi

}

function bedtime {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    local do_phone=1
    local wifi=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -p)
            do_phone="$2"
            shift 2
            ;;
        -w)
            wifi="$2"
            shift 2
            ;;
        -h | --help)
            print 'Usage: bedtime [options...]'
            printf " %-3s %-20s %s\n" "-p" "<1/0>" "Do set phone settings"
            printf " %-3s %-20s %s\n" "-w" "<1/0>" "Wifi on/off"
            printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
            return 0
            ;;
        *)
            echo "Unknown option: $1"
            return 1
            ;;
        esac
    done

    echo "Temp: $(sens temp)°C"

    if [[ $(sens temp) -lt 22.5 ]]; then
        echo "Turn on radiator"
    fi

    if [[ $do_phone -eq 1 ]]; then
        short phondo "flight mode"
    fi

    if [[ $wifi -eq 1 ]]; then
        wifi on
    else
        sleep 2
        wifi off
    fi

    short focus sleep

    ob "p/auto/state bedtime" | state_switch.sh

    ob bedtime
    ob zink

    local uptime=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
    if [[ $uptime -lt $(date -v-3d +%s) ]]; then
        read "response?Shut down? (y/n): "
        if [[ "$response" == "y" ]]; then
            sudo shutdown -h now
        fi
    fi

    if pgrep -x Arc; then
        read "response?Close browser? (y/n): "
        if [[ "$response" == "y" ]]; then
            pkill -2 Arc
        fi
    fi
}

# ========================== HELPERS ========================= #

function bed_minus_dinner { time_diff.sh -mp $(date +%H:%M) $(tl.sh 'routines/bed_time/start?sep=%3A'); }

function fall_asleep_delay {
    local bedtime=$(curl -s "$ROUTINE_ENDPOINT?q=bed_time" | sed 's/\./:/g' 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$bedtime" ]; then
        return 1
    fi

    local sleep_time=$(is sleep_start 1 | hm | jq '.[]' | sed 's/"//g' 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$sleep_time" ]; then
        return 1
    fi
    sleep_time=$(time_diff.sh "12:00" "$sleep_time")

    local time=$(time_diff.sh -p $bedtime $sleep_time)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local hours=${time%%:*}
    local minutes=${time#*:}
    echo $((hours * 60 + minutes))
}

function bed_minus_detach {
    local detach_time=$(tl.sh 'routines/detach/end?sep=%3A' 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$detach_time" ]; then
        return 1
    fi

    local bed_time=$(tl.sh 'routines/bed_time/start?sep=%3A' 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$bed_time" ]; then
        return 1
    fi

    local time=$(time_diff.sh $detach_time $bed_time)

    local hours=${time%%:*}
    local minutes=${time#*:}
    echo $((hours * 60 + minutes))
}

function calc_brightness {
    day_length=$(is -v "day_length" 1)
    cloud_cover=$(is -v "weather_cloud_cover" 1)
    precipitation=$(is -v "weather_precipitation" 1)
    humidity=$(is -v "weather_humidity" 1)

    brightness=$(echo "$day_length * (1 - 0.8 * $cloud_cover) * (1 - 0.5 * $precipitation) * (1 - 0.3 * $humidity)" | bc -l | awk '{printf("%d\n",$1 + 0.5)}')

    if [[ $brightness -gt 0 ]]; then
        echo $brightness
    fi
}
