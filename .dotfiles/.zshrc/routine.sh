
## @function eat 
## @param {string[]}  Arguments to pass to `loc` function
function eat {
    local maybe_home=$(is_home --guess-yes)
    in_window.sh 11:30 14:30 && local is_lunch=true || local is_lunch=false
    in_window.sh 17:00 $(map.sh routine.detach 20:00) && local is_dinner=true || local is_dinner=false

    # If home
    if $maybe_home; then
        $MY_SCRIPTS/lang/shell/battery.sh 60
        [[ -n "$1" ]] && ( loc -S "$@" & )
    fi

    # If lunch
    if $is_lunch; then
        echo "Do florinef?"
    fi

    # If dinner
    if $is_dinner; then
        ( short -s night_shift 1 & )

        # Handle temperature
        if $maybe_home; then
            local temp=$(loc -S -n sens/temp)
            local dinner_temp_threshold=21
            
            if (( $temp > $dinner_temp_threshold )); then
                echo "Turn off radiator - ( $temp°C > $dinner_temp_threshold°C )"
            fi
        fi

        # Handle creatine
            # local did_creatine=$(tl.sh habits | jq '.creatine')
            # if ! $did_creatine; then
            #     echo "Creatine - ( not taken )"
            # fi

        # Track time
        ({
            local time_diff=$(bed_minus_dinner)
            [ -n "$time_diff" ] && a "bed_minus_dinner $time_diff s #u"
        }&)
    fi

    if $is_lunch || $is_dinner; then
        if ! (ob b | grep -q cook) && ask "Add cook?"; then
            a "cook #b @home"
        fi

        if map -s 's.headache' false; then
            echo "Cold pad - ( headache )"
        fi 
    fi

    if ! $maybe_home; then
        echo "chew"
    fi

    echo
    ob meal
}

## @function eat 
## @param {string[]}  Arguments to pass to `loc` function
function back {
    ( loc "$@" & )
    
    ob back
}

# ================================ TIME BOUND ================================ #

function wake {
    a 'c wake'

    # Woke acedentally
    if ask 'Involontary?'; then
        a 't woke_early'
        ask 't melatonin?' && a 't melatonin'
        obc woke

    # Woke deliberatelly
    else
        ({
            red_mode 0
            dnd 0
            short -s night_shift 0
        }&)


        # Handle cortisone
        local cort_taken
        vared -p 'Cort amt: ' -c cort_taken
        if [[ -n $cort_taken && $cort_taken != 0 ]]; then
            a "cort ; $cort_taken #tmp"

            if [[ $cort_taken -ge 10 ]]; then
                echo 'Drink water - ( cort >= 10 )'
            fi
        fi

        ob wake

        if ! is_home --guess-yes; then
            obc stayover

            if ask "obc social?"; then
                a 't social away'
                obc social
            fi
        fi

        wake_state
    fi

    if [[ -n $1 ]]; then
        wifi on
        ({
            while ! ping -c 1 -t 1 8.8.8.8 &>/dev/null; do
                sleep 0.3
            done

            loc p "$1"
        }&)
    fi
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

    # if ask "Light theme?"; then
    #     theme 0
    # else
    #     theme 1
    # fi

    # sync ------------------------------------------------------- #

    while ! ping -c 1 -t 1 8.8.8.8 &>/dev/null; do
        sleep 0.3
        echo "(waiting for internet...)"
    done

    ({
        local brightness=$(calc_brightness)
        [[ -n "$brightness" && "$brightness" -ge 400 ]] && echo "Brightness: $brightness"
    }&)

    td s
    state_calc && daily_calcs

    # env -------------------------------------------------------- #

    ({
        dnd 0
        short -N -s focus "$focus_mode"
        short -s night_shift "$night_shift"
        red_mode 0
    }&)

    # display ---------------------------------------------------- #

    local cal=$(short -m -N day tod)
    echo "$cal" | to_color.sh blue

    ob dawn

    # Display secondary stuff
    glo habits streak

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
        a '> plan &<wbr>& echo #b'
    fi

    if map.sh -s 's.headache'; then
        obc 'head period'
    fi

    tdi
    echo $cal | $MY_SCRIPTS/secret/agenda_switch.sh
    ob p | $MY_SCRIPTS/secret/agenda_switch.sh
    ob b | $MY_SCRIPTS/secret/agenda_switch.sh
}

function eve {
    local screen decomp tv
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    if $MY_SCRIPTS/lang/shell/is_help.sh $*; then
        print 'Usage: eve [options...]'
        printf " %-3s %-20s %s\n" "-F," "" "Skip flight mode"
        printf " %-3s %-20s %s\n" "-E," "" "Skip environment setup"
        printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
        return 0
    fi

    # environment ------------------------------------------------ #

    if [[ ! " $@ " == *" -E "* ]]; then
        short -s focus sleep # NOTE - should run early, before short phondo
        short -s night_shift 1
        theme 1
    fi

    # reset ---------------------------------------------------------------------- #

    if [[ $(ob rule | lines) -gt 1 ]]; then
        ob rule
    fi

    do_now -Dw p/risk
    do_now -Dw p/rule
    do_now -Dw p/p

    # other info ------------------------------------------------- #

    info tom | grep -vE 'detach|full_detach|full_detach|bed_time'
    echo

    # Display weather if snow
    local forecast=$(weather)
    if echo $forecast | grep -q "snow"; then
        echo "$forecast"    
        if ask "Add ear plugs? - snow"; then 
            a "ear plugs #b"
        fi
    fi

    if weather /moon T | grep -q "Full Moon"; then
        echo "Full Moon"
        a "t full_moon #u"
    fi

    $MY_SCRIPTS/lang/shell/battery.sh 40

    tl.sh habits

    local xLen=$(ob x | dale)
    if [[ $xLen -eq 0 ]]; then
        echo "Do excuse practice"
    fi

    local temp=$(loc -S sens/temp)
    if [[ $temp -ge 21 ]]; then
        echo "Cool down - ( $temp >= 21°C )"
    fi

    if map.sh -s 's.sleepy'; then
        echo "Turn off alarm? - ( sleepy )"
    fi

    echo

    # manual track ------------------------------------------------- #

    vared -p "Screen: " -c screen
    if [[ -n "$screen" ]]; then 
        local screen_min=$(hm $screen)
        a "screen $screen_min s #u"
    fi

    vared -p "Decomp: " -c decomp
    if [[ -n "$decomp" ]]; then 
        local decomp_min=$(hm $decomp)
        a "decomp $decomp_min #u"
    fi

    vared -p "TV: " -c tv
    if [[ -n "$tv" ]]; then 
        local tv_min=$(hm $tv)
        a "tv $tv_min s #u"
    fi

    # auto track ------------------------------------------------- #

    (eve_track &)

    a '#tmp done ; detach'
    a "p_ett $(tdis | lines) s #u"
    (short track_away &)


    # display main ----------------------------------------------- #

    ob eve

    $HOME/.dotfiles/scripts/lang/shell/battery.sh 50
    ob "p/auto/state eve act.md" | state_switch.sh

    if [[ $(date +"%m") -gt 5 ]] && [[ $(date +"%m") -le 8 ]]; then # Is Jun, Jul or Aug
        echo "optimize melatonin"
    fi

   local load_res=$(is -v "load" 1)
   if [[ "$load_res" -gt 6 ]]; then
       a "#b :p load - %% $load_res %% "
   fi

    # flight mode ------------------------------------------------ #

    if [[ ! " $@ " == *" -F "* ]]; then
        read
        short phondo "flight mode"
        dnd 1
    fi

    # other ------------------------------------------------------------ #

    later
    ask "Do wind-down activity later instead?" && a "#b [[detach]]"
}

function bedtime {
    ( bedtime_state & )

    short -s focus sleep
    # short -s bedtime_brightness
    loc p 'night?m=keep'

    local decomp=""
    vared -p "Decomp: " -c decomp
    if [[ -n "$decomp" ]]; then 
        local decomp_min=$(hm $decomp)
        a "decomp $decomp_min #u"
    fi

    a 'flush @rm'

    # display -------------------------------------------------------------------- #

    # if [[ $(loc -S sens/temp) -lt 21 ]]; then
    #     echo "Turn on radiator - ( $temp°C < 21°C )"
    # fi

    local month=$(date +%m)
    if [[ "$month" == "03" || "$month" == "04" || "$month" == "05" ]]; then
        echo "earbuds"
    fi

    loc led "green?a=off" 2>/dev/null
    loc led "red?a=off" 2>/dev/null
    ob "p/auto/state bedtime" | state_switch.sh

    ob bedtime
    ob zink

    if [[ $(date +"%m") -le 2 || $(date +"%m") -ge 9 ]]; then
        echo "have warm clothes near"
        echo "scarf?"
    fi

    local state_input
    vared -p "State: " -c state_input
    [[ -n "$state_input" ]] && a "$state_input #state"

    [[ $(ob plan | lines) -lt 4 ]] && plan

    # shut down ------------------------------------------------------------------ #

    if ask "Set flight mode on phone?"; then
        short -s phondo "flight mode"
    fi

    local uptime=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
    if [[ $uptime -lt $(date -v-8d +%s) ]]; then
        if ask "Shut down?"; then
            wait
            sudo shutdown -h now
        fi
    fi

    if ask "Turn off wifi?"; then
        wait
        wifi off
        pkill -2 $BROWSER
    else
        if pgrep -x $BROWSER; then
            if ask "Close browser?"; then
                pkill -2 $BROWSER
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
        local sleep_start=$(is -v sleep_start 1 | hm | sed 's/"//g' 2>/dev/null)
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
