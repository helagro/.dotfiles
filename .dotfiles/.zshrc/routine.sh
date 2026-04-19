
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

    if [[ ( $is_lunch || $is_dinner ) && $maybe_home ]]; then
        if ! (ob b | grep -q cook) && ask "Add cook?"; then
            a "cook #b @home"
        fi

        if map -s s.headache || map -s s.stiff; then
            echo "Cold pad"
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
    ( loc "$@" & ) &>/dev/null
    
    # TODO - add calm down routine with timer
    
    do_now -w p/return > /dev/null
    ob back | cat
}

# ================================ TIME BOUND ================================ #

function wake {
    a 'c wake'

    # Woke acedentally
    if ask 'Involontary?'; then
        a 'woke_early 1'
        ask 'yesterday melatonin 1?' && a 'yesterday melatonin 1'
        obc woke

    # Woke deliberatelly
    else
        ({
            red_mode 0
            dnd 0
        }&)

        # Handle cortisone
        local cort_taken
        vared -p 'Cort amt: ' -c cort_taken
        if [[ -n $cort_taken && $cort_taken != 0 ]]; then
            a "cort ; $cort_taken #tmp"

            if [[ $cort_taken -ge 10 ]]; then
                echo 'Drink water - ( cort >= 10 )'
                local cort_task=$(tdls tod | grep 'cort 10')

                if is_online; then
                    ( tdc $cort_task & )
                else
                    later "tdc '$cort_task'"
                fi
            elif [[ $cort_taken -eq 0 ]]; then
                a '#b do morning cort'
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
    local do_env=true

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
        -E | --skip-env)
            do_env=false
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

    (
        td s &
        state_calc && daily_calcs &
        wait
    )

    # env -------------------------------------------------------- #

    $do_env && ({
        dnd 0
        short -N -s focus "$focus_mode"
        short -s night_shift "$night_shift"
        red_mode 0
    }&)

    # display ---------------------------------------------------- #

    local cal=$(info tod)
    echo "$cal" | to_color.sh blue

    obc dawn

    # Display secondary stuff
    glo habits streaks | bat -p --color=always -l json

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

    if map.sh -s 's.headache' && ! map.sh -s 's.off'; then
        obc 'head period'
    fi

    echo $cal | "$MY_SCRIPTS/secret/agenda_switch.sh"
    ob p | "$MY_SCRIPTS/secret/agenda_switch.sh"
    ob b | "$MY_SCRIPTS/secret/agenda_switch.sh"

    # Other
    (
        is_home && do_now -w p/return & 
    ) 
}

function eve {
    local screen decomp tv
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    if "$MY_SCRIPTS/lang/shell/is_help.sh" "$*"; then
        print 'Usage: eve [options...]'
        printf " %-3s %-20s %s\n" "-F," "" "Skip flight mode"
        printf " %-3s %-20s %s\n" "-E," "" "Skip environment setup"
        printf " %-3s %-20s %s\n" "-h," "--help" "Show this help message"
        return 0
    fi

    # environment ------------------------------------------------ #

    if [[ ! " $@ " == *" -E "* ]]; then
        (loc p eve &) 2>/dev/null
        theme 1

        short -s focus sleep # NOTE - should run early, before short phondo
        short -s night_shift 1
    fi

    # reset ---------------------------------------------------------------------- #

    if [[ $(ob rule | lines) -gt 1 ]]; then
        ob rule
    fi

    do_now -Dw p/risk
    do_now -Dw p/rule
    do_now -Dw p/plan/p

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

    "$MY_SCRIPTS/lang/shell/battery.sh" 40

    if ! map.sh -s done.excuse; then
        echo "Do excuse practice"
    fi

    if map -s s.off; then
        a '#b retrospective - off'
    fi

    local temp=$(loc -S sens/temp)
    if [[ $temp -ge 21 ]]; then
        echo "Cool down - ( $temp >= 21°C )"
    fi

    if [[ $(date +%a) == (Fri|Sat) ]]; then
        echo "Earplugs - weekend"
    fi

    if map.sh -s 's.sleepy'; then
        echo "Turn off alarm? - sleepy"
    fi

    printf 'Cort: '
    is -v 'cort' 1

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

    # display main ----------------------------------------------- #

    clear
    ob eve

    "$HOME/.dotfiles/scripts/lang/shell/battery.sh" 50
    ob "p/auto/state eve act.md" | state_switch.sh

    if [[ $(date +"%m") -gt 5 ]] && [[ $(date +"%m") -le 8 ]]; then # Is Jun, Jul or Aug
        echo "optimize melatonin"
    fi

   local load_res=$(is -v "load" 1)
   if [[ "$load_res" -gt 6 ]]; then
       a "#b :p load - %% $load_res %% "
   fi

   if [[ $(date +%u) -eq 6 ]] && map.sh -s s.off; then
       echo "LOG #week"
   fi

    # flight mode ------------------------------------------------ #

    if [[ ! " $@ " == *" -F "* ]]; then
        read
        short phondo "flight mode"
        dnd 1
    fi

    # other ------------------------------------------------------------ #

    later

    if in_window.sh 00:00 $(map routine.full_detach 21:30) && ! map -s s.off; then
        ask "Do wind-down activity later instead?" && a "#b [[detach]]"
    fi
}

function bedtime {
    ( bedtime_state & ) 2>/dev/null

    short -s focus sleep
    (
        [[ -n $1 ]] && loc "$@" &
        loc led "green?a=off" &
        loc led "red?a=off" &
    ) 2>/dev/null

    local decomp=""
    vared -p "Decomp: " -c decomp
    if [[ -n "$decomp" ]]; then 
        local decomp_min=$(hm $decomp)
        a "decomp $decomp_min #u"
    fi

    # Flush tasks in desktop
    a 'flush @rm'

    # display -------------------------------------------------------------------- #

    # if [[ $(loc -S sens/temp) -lt 21 ]]; then
    #     echo "Turn on radiator - ( $temp°C < 21°C )"
    # fi

    local month=$(date +%m)
    if [[ "$month" == "03" || "$month" == "04" || "$month" == "05" ]]; then
        echo "earbuds? - spring"
    fi

    ob "state bedtime" | state_switch.sh

    ob bedtime

    local zink_len=$(ob zink | lines)
    if [[ zink_len -ge 6 ]]; then
        printf "len zink : "
        ob zink | lines
    fi

    if [[ $(date +"%m") -le 2 || $(date +"%m") -ge 9 ]]; then
        echo "have warm clothes near"
        echo "scarf?"
    fi

    if [[ $(map s.sleep_delay) -ge 90 ]]; then
        echo "sleep somewhere different - sleep delay"
    fi

    [[ $(ob plan | lines) -lt 4 ]] && plan

    # shut down ------------------------------------------------------------------ #

    if is_home --not-offline && ask "Set flight mode on phone?"; then
        short -s phondo "flight mode"
    fi

    local uptime=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
    if [[ $uptime -lt $(date -v-8d +%s) ]]; then
        if ask "Shut down?"; then
            wait
            sudo shutdown -h now
        fi
    fi

    if is_online && ask "Turn off wifi?"; then
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
    a "p_ett $(tdis | lines) #u"
    (short track_away &)
    ("$MY_SCRIPTS/lang/shell/track_pollen.sh" &) >/dev/null

    # Track sleep delay
    local sleep_delay=$(fall_asleep_delay)
    if [[ $? -eq 0 && -n "$sleep_delay" ]]; then
        a "$(day -1) sleep_delay $sleep_delay #u"
        map set s.sleep_delay $sleep_delay
    fi

    # Track bedtime minus detach
    local bed_minus_detach=$(bed_minus_detach)
    [[ -n "$bed_minus_detach" ]] && a "bed_minus_detach $bed_minus_detach #u"

    # Track brightness
    local brightness=$(calc_brightness)
    [[ -n "$brightness" ]] && a "brightness $brightness #u"

    if is_home && ! map -s done.clean; then
        local last_cleaned_ago=$(is -v 'cleaned_ago' 1 -u 1 2>/dev/null)
        [[ -n "$last_cleaned_ago" && "$last_cleaned_ago" != "null" ]] && a "cleaned_ago $((last_cleaned_ago + 1)) #u"
    fi

    if map -s s.social; then
        a "social_ago 0 #u"
    else
        local last_social_ago=$(is -v 'social_ago' 1 -u 1 2>/dev/null)
        [[ -n "$last_social_ago" && "$last_social_ago" != "null" ]] && a "social_ago $((last_social_ago + 1)) #u"
    fi
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
    local sleep_delay=$((hours * 60 + minutes))
    if [[ $sleep_delay -lt 0 ]]; then
        return 1
    fi

    echo $sleep_delay
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
