function wake {
    wifi on
    red_mode 0
    short -s night_shift 0
    loc -S dev eve lvl 100 >/dev/null

    local cort_taken
    vared -p 'Cort amt: ' -c cort_taken

    if [[ -n $cort_taken && $cort_taken != 0 ]]; then
        a "took cort $cort_taken #e"

        if [[ $cort_taken -ge 10 ]]; then
            echo 'Drink water - ( cort >= 10 )'
        fi
    fi

    wake_state
}

function dawn {
    wifi on

    local focus_mode="off"
    local night_shift=0

    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --focus)
            focus_mode="$2"
            shift 2
            ;;
        -n | --night)
            night_shift=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            return 1
            ;;
        esac
    done

    if ask "Light theme?"; then
        theme 0
    else
        theme 1
    fi

    # sync ------------------------------------------------------- #

    while ! ping -c 1 -t 1 8.8.8.8 &>/dev/null; do
        sleep 0.5
        echo "(waiting for internet...)"
    done

    (
        (
            local brightness=$(calc_brightness)
            [[ -n "$brightness" && "$brightness" -ge 400 ]] && echo "Brightness: $brightness"
        ) &
    )

    td s
    state_calc && daily_calcs

    # env -------------------------------------------------------- #

    short -N -s focus "$focus_mode"
    short -s night_shift "$night_shift"
    red_mode 0

    # display ---------------------------------------------------- #

    local cal=$(short -m -N day tod)
    echo "$cal" | to_color.sh blue

    ob dawn

    # Display secondary stuff
    glo habits streak
    for state in "${state_list[@]}"; do
        $(eval echo \$$state) && echo $state
    done | to_color.sh magenta

    local forecast=$(weather -l 1)
    if echo $forecast | grep -q "rain"; then
        echo "$forecast"
    fi

    wait
    later
    echo

    [[ $(ob rule | lines) -gt 1 ]] && ob rule
    [[ $(ob risk | lines) -gt 1 ]] && ob risk
    if [[ $(ob p | lines) -gt 1 ]]; then
        ob p
    else
        a 'plan - big_break | exor | return #b'
    fi

    if state.sh -s 'headache'; then
        obc 'head period'
    fi

    tdi
    echo $cal | $MY_SCRIPTS/secret/agenda_switch.sh
    ob p | $MY_SCRIPTS/secret/agenda_switch.sh
}

## @function eat 
## @param {string[]}  Arguments to pass to `home` function
function eat {
    $MY_SCRIPTS/lang/shell/battery.sh 60
    ( home "$@" & )

    # If dinner
    if in_window.sh 17:00 20:00; then
        # Handle temperature
        local temp=$(loc -S -n sens/temp)
        if [[ $temp -gt $dinner_temp_threshold ]]; then
            echo "Turn off radiator - ( $temp°C > $dinner_temp_threshold°C )"
        fi

        # Handle creatine
        local did_creatine=$(tl.sh habits | jq '.creatine')
        if ! $did_creatine; then
            echo "Creatine - ( not taken )"
        fi

        # Track time
        local time_diff=$(bed_minus_dinner)
        [ -n "$time_diff" ] && a "bed_minus_dinner $time_diff s #u" && echo "tracked bed_minus_dinner AS $time_diff"
    fi

    echo
    ob meal
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

    ob x | grep -qF $(day) && a "x"

    # environment ------------------------------------------------ #

    if [[ ! " $@ " == *" -E "* ]]; then
        short -s focus sleep # NOTE - should run early, before short phondo
        short -s night_shift 1
        theme 1
        pkill 'ChatGPT'
    fi

    # reset ---------------------------------------------------------------------- #

    if [[ $(ob rule | lines) -gt 1 ]]; then
        ob rule
    fi

    do_now -Dw p/risk
    do_now -Dw p/rule
    do_now -Dw p/p

    # other info ------------------------------------------------- #

    later
    info tom | grep -vE 'detach|full_detach|full_detach|bed_time'
    echo

    # Display weather if snow
    local forecast=$(weather)
    if echo $forecast | grep -q "snow"; then
        echo "$forecast"
    fi

    $MY_SCRIPTS/lang/shell/battery.sh 40

    tl.sh habits

    local temp=$(loc -S sens/temp)
    if [[ $temp -ge 21 ]]; then
        echo "Cool down - ( $temp >= 21°C )"
    fi

    if state.sh -s 'sleepy'; then
        echo "Turn off alarm? - ( sleepy )"
    fi

    echo

    # manual track ------------------------------------------------- #

    vared -p "Main: " -c main
    [[ -n "$main" ]] && a "main $(hm $main) #u"

    vared -p "Screen: " -c screen
    [[ -n "$screen" ]] && a "screen $(hm $screen) s #u"

    # auto track ------------------------------------------------- #

    (eve_track &)

    a "p_ett $(tdis | lines) s #u"
    (short track_away &)


    # display main ----------------------------------------------- #

    ob eve

    $HOME/.dotfiles/scripts/lang/shell/battery.sh 50
    ob "p/auto/state eve act.md" | state_switch.sh

    if [[ $(date +"%m") -gt 5 ]] && [[ $(date +"%m") -le 8 ]]; then # Is Jun, Jul or Aug
        echo "optimize melatonin"
    fi

   local e1_res=$(is -v "$e1" 1)
   if [[ "$e1_res" == "1" ]]; then
       ask "cort_diff -2.5?" && a "cort_diff -2.5 #u"
   fi

    # flight mode ------------------------------------------------ #

    if [[ ! " $@ " == *" -F "* ]]; then
        read
        short phondo "flight mode"
    fi
}

function bedtime {
    short -s focus sleep
    short -s home bedtime
    short -s bedtime_brightness

    a 'flush @rm'

    # display -------------------------------------------------------------------- #

    # if [[ $(loc -S sens/temp) -lt 21 ]]; then
    #     echo "Turn on radiator - ( $temp°C < 21°C )"
    # fi

    local month=$(date +%m)
    if [[ "$month" == "03" || "$month" == "04" || "$month" == "05" ]]; then
        echo "earbuds"
    fi

    ob "p/auto/state bedtime" | state_switch.sh

    ob bedtime
    ob zink

    if [[ $(date +"%m") -le 2 || $(date +"%m") -ge 9 ]]; then
        echo "have warm clothes near"
    fi

    local state_input
    vared -p "State: " -c state_input
    [[ -n "$state_input" ]] && a "$state_input #state"

    # shut down ------------------------------------------------------------------ #

    if ask "Set flight mode on phone?"; then
        short -s phondo "flight mode"
    fi

    local uptime=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
    if [[ $uptime -lt $(date -v-8d +%s) ]]; then
        if ask "Shut down?"; then
            sudo shutdown -h now
        fi
    fi

    if ask "Turn off wifi?"; then
        wifi off
        pkill -2 Arc
    else
        if pgrep -x Arc; then
            if ask "Close browser?"; then
                pkill -2 Arc
            fi
        fi
    fi
}

# ========================== HELPERS ========================= #

function bed_minus_dinner { time_diff.sh -mp $(date +%H:%M) $(tl.sh 'routines/bed_time/start?sep=%3A'); }

function eve_track {
    # Track sleep delay
    local sleep_delay=$(fall_asleep_delay)
    [ $? -eq 0 ] && [ -n "$sleep_delay" ] && a "$(day -1) sleep_delay $sleep_delay s #u"

    # Track bedtime minus detach
    local bed_minus_detach=$(bed_minus_detach)
    [ -n "$bed_minus_detach" ] && a "$(day) bed_minus_detach $bed_minus_detach s #u"

    # Track brightness
    local brightness=$(calc_brightness)
    [ -n "$brightness" ] && a "$(day) brightness $brightness s #u"

    # Can't be called in morning because of offline items
    a "$(day -1) mindwork $(is -v meditation_min 1 1) #u"
}

function fall_asleep_delay {
    local bedtime=$(curl -s "$ROUTINE_ENDPOINT?q=bed_time" | sed 's/\./:/g' 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$bedtime" ]; then
        return 1
    fi

    if [[ -n $1 ]]; then
        # Perminant debug option
        local sleep_start="$1"
    else
        local sleep_start=$(is sleep_start 1 | hm | jq '.[]' | sed 's/"//g' 2>/dev/null)
    fi

    if [ $? -ne 0 ] || [ -z "$sleep_start" ] || [[ $sleep_start == "null" ]]; then
        return 1
    fi

    # Converts to 24-hour format from starting at 12:00 (but not normal 12h clock!)
    sleep_start=$(time_diff.sh "12:00" "$sleep_start")

    # echo "Sleep start: $sleep_start"
    # echo "Bedtime: $bedtime"
    local time=$(time_diff.sh $bedtime $sleep_start)
    if time_diff.sh -p "12:00" "$time" >/dev/null; then
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

    brightness=$(echo "($day_length/31)^2 * (1 - 0.8 * $cloud_cover) * (1 - 0.5 * $precipitation) * (1 - 0.3 * $humidity)" | bc -l | awk '{printf("%d\n",$1 + 0.5)}')

    if [[ $brightness -gt 0 ]]; then
        echo $brightness
    fi
}
