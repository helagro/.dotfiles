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

    # env -------------------------------------------------------- #

    short focus "$focus_mode"
    short night_shift "$night_shift"
    short focus
    theme $theme

    sleep 2

    # add to checklist ------------------------------------------- #

    local risk_amt=$(ob risk | wc -l | tr -d '[:space:]')
    if [[ $risk_amt -le 1 ]]; then
        later "# risk.md"
    fi

    # states ----------------------------------------------------- #

    a "dawn #u"
    ob "p/auto/state adder" | state_switch.sh | a
    ob "p/auto/state do" | state_switch.sh | later "stdin"

    local sleep_amt=$(is sleep 1 | jq '.[]')
    local sleep_amt_yd=$(is sleep 1 1 | jq '.[]')
    if missing_sleep $sleep_amt || missing_sleep $sleep_amt_yd; then
        do_now "p/auto/is low sleep"
    fi

    local headache=$(is head 1 | jq '.[]')
    if ! missing_sleep $sleep_amt && [[ $headache != '1' ]]; then
        later "a '#b workspace' #plan"
    fi

    local yd_water=$(is water 1 1 | jq '.[]')
    if [[ $yd_water -le 1100 ]]; then
        later "#water_yd: $yd_water -> hydrate"
    fi

    if [[ $(date +"%m") -le 2 ]]; then # Is Jan or Feb
        later "#plan sunlight exposure"
        a "winter 1 s #u"
    fi

    # display ---------------------------------------------------- #

    later
    echo

    # Display main stuff
    day tod
    ob dawn

    # Display secondary stuff
    tl.sh streaks
    for state in "${state_list[@]}"; do
        $(eval echo \$$state) && echo $state
    done
    ob rule
    ob p
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

    # show stats ------------------------------------------------- #

    printf "podd: \e[33m%b\e[0m\n" "$(is -v podd 1)"
    printf "tv_min: \e[33m%b\e[0m\n" "$(is -v tv_min 1)"
    printf "tv_opens: \e[33m%b\e[0m\n" "$(is -v tv_opens 1)"

    echo

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

    # Track main
    local main
    echo -n "main: "
    read -r main
    a "main $(hm $main) s #u"

    # Track screen
    local screen
    echo -n "screen: "
    read -r screen
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

    # State conditionals
    $has_fog && echo "fog -> ( walk, meditate )"
    $has_headache && echo "fog -> ( walk, meditate )"

    echo

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

    local time=$(time_diff.sh $bedtime $sleep_time)

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
