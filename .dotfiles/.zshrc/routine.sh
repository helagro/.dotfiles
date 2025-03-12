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

    while ! ping -c 1 -t 1 8.8.8.8 &>/dev/null; do
        sleep 0.5
        echo "(waiting for internet...)"
    done

    # state ------------------------------------------------------ #

    # NOTE - Needs to run early to complete before "later"
    (state_calc && dawn_state) &

    # env -------------------------------------------------------- #

    short -s focus "$focus_mode"
    short -s night_shift "$night_shift"
    theme $theme

    # display ---------------------------------------------------- #

    # Display main stuff
    day tod
    ob dawn

    # Display secondary stuff
    tl.sh streaks
    for state in "${state_list[@]}"; do
        $(eval echo \$$state) && echo $state
    done
    state.sh | jq -r 'to_entries[] | select(.value == true) | .key' | to_color.sh magenta

    wait
    later
    echo

    ob rule
    ob p

    # lastly ----------------------------------------------------- #

    a "dawn #u"
}

function dinner {
    local temp=$(sens -n temp)
    if [[ $temp -gt $dinner_temp_threshold ]]; then
        echo "Turn off radiator - ( $temp°C > $dinner_temp_threshold°C )"
    fi

    local did_creatine=$(tl.sh hb | jq '.creatine')
    if ! $did_creatine; then
        echo "Creatine - ( not taken )"
    fi

    # Track time
    local time_diff=$(bed_minus_dinner)
    [ -n "$time_diff" ] && a "bed_minus_dinner $time_diff s #u" && echo "tracked bed_minus_dinner AS $time_diff"

    echo
    ob dinner
    ob eat
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
    a "water | blinds #b #u"

    # Reset
    echo "" >$VAULT/p/risk.md
    echo "" >$VAULT/p/p.md

    # other info ------------------------------------------------- #

    # Display Tasks
    day tom
    echo

    # Display weather if snow
    forecast=$(weather)
    if [ -n "$forecast" ] | grep -q "snow"; then
        echo "$forecast"
    fi

    tl.sh hb

    echo -n temp:
    sens temp

    echo

    # manual track ------------------------------------------------- #

    echo "https://track.toggl.com/timer"

    vared -p "Main: " -c main
    a "main $(hm $main) s #u"

    vared -p "Screen: " -c screen
    a "screen $(hm $screen) s #u"

    # auto track ------------------------------------------------- #

    a "eve #u"
    a "p_ett $(tdis | lines | tr -d '[:space:]') s #u"

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

    # display main ----------------------------------------------- #

    # Show note
    ob eve

    # Show charge
    local battery_level=$(pmset -g batt | grep -o '[0-9]*%' | tr -d '%')
    if [ $battery_level -lt 50 ]; then
        echo "Charge: $battery_level%"
    fi

    # State conditionals
    ob "p/auto/state eve act.md" | state_switch.sh

    b.sh

    # environment ------------------------------------------------ #

    if [[ ! " $@ " == *" -E "* ]]; then
        short focus sleep
        short night_shift 1
        theme 1
    fi

    # auto del --------------------------------------------------- #

    # Deletes tasks tagged @rm. NOTE - Has safeties and redundancies
    local del_tasks=$(tdls '@rm' -epF 'p1' | grep '@rm' | head -n 10)
    echo "$del_tasks" >>$HOME/.dotfiles/logs/eve.log
    local del_ids=$(echo -n "$del_tasks" | grep -o '^[0-9]*' | tr -s '[:space:]' ' ')

    if tdc $del_ids; then
        echo "Auto-deleted $(echo -n "$del_ids" | wc -w | tr -d '[:space:]') task(s)"
    else
        echo 'Auto task deletion failed'
    fi

    # flight mode ------------------------------------------------ #

    if [[ ! " $@ " == *" -F "* ]]; then
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

    sens temp

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
    ob bedtime
    ob zink

    read "response?Shut down? (y/n): "
    if [[ "$response" == "y" ]]; then
        sudo shutdown -h now
    fi

    read "response?Close browser? (y/n): "
    if [[ "$response" == "y" ]]; then
        pkill -2 Arc
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
