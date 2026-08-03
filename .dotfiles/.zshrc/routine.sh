
## @function back
## @param {string[]}  Arguments to pass to `loc` function
function back {
    ( loc "$@" & ) &>/dev/null
    
    # TODO - add calm down routine with timer
    
    do_now -w p/situation/return > /dev/null
    ob back | cat
}

function cook {
    ( loc p out & ) &>/dev/null
    map.sh -s ps.off && echo $chore_reminder

    if map.sh -s ps.off; then
        obc diet
    fi

    if ! map.sh -m -s act.current; then
        act -n "cook" -L
    fi
}

# ================================ TIME BOUND ================================ #

function wake {
    # woke accidentally ----------------------------------------------------------- #

    if ask 'Involontary?'; then
        a 'woke_early 1'
        ask 'yesterday melatonin 1?' && a 'yesterday melatonin 1'
        obc woke

    # woke deliberatelly --------------------------------------------------------- #
    else
        ({
            red_mode 0
            dnd 0
        }&)

        # Handle cortisone
        local cort_taken
        vared -p 'Cort amt: ' -c cort_taken
        if [[ $cort_taken -eq 0 ]] && { tdls tod | grep 'cort 10'; }; then
            a '#b cort 10'
        fi

        ob wake

        if map.sh -s opt.presentable && ! map.sh -s ps.off; then
            echo "Salt rinse - presentable"
        else
            a '#b **salt rinse** @mv'
        fi

        if ! is_home --guess-yes; then
            if is_orust; then
                obc orust
            elif ask "obc stayover?"; then
                a 'social 1 ; away 1'
                a '!(13:00) eat lunch @rm'
                obc stayover
            else
                a 'away 1'
            fi
        fi

        wake_extra "$cort_taken"
    fi

    # execute things needing internet -------------------------------------------------------- #

    if [[ -n $1 || ( -n $cort_taken && $cort_taken != 0 ) ]]; then
        wifi on
        ({
            while ! ping -c 1 -t 1 8.8.8.8 &>/dev/null; do
                sleep 0.3
            done

            if [[ -n $1 ]]; then
                loc "$@"
            fi

            if [[ -n $cort_taken ]]; then
                a "cort ; $cort_taken #tmp"
                map.sh inc s.cort "$cort_taken"

                if [[ $cort_taken -ge 10 ]]; then
                    local cort_task=$(tdls tod | grep 'cort 10')
                    ( tdc $cort_task & )
                fi
            fi
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

    # sync ------------------------------------------------------- #

    while ! ping -c 1 -t 1 8.8.8.8 &>/dev/null; do
        sleep 0.3
        echo "(waiting for internet...)"
    done

    (
        td s &
        dawn_extra &
        { state_calc && daily_calcs } &
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

    local streaks=$(glo habits streaks)
    echo "$streaks" | bat -p --color=always -l json
    map.sh set 's.gym_ago' "$(echo "$streaks" | jq '.gym')"

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
        a 'plan` - missing #b'
    fi

    if map.sh -s 's.headache' && ! map.sh -s 'ps.off'; then
        obc 'head period' -s
    fi

    echo $cal | "$MY_SCRIPTS/secret/agenda_switch.sh"
    ob p | "$MY_SCRIPTS/secret/agenda_switch.sh"
    ob b | "$MY_SCRIPTS/secret/agenda_switch.sh"

    # Other
    ({
        if is_home; then
            do_now -w p/situation/return

            if (( $(loc sens temp) > 25 )); then
                a '#b open window - ( temp > 25°C )'
            fi
        fi
    }&) 
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

    local month=$(date +%m)
    [[ $(date +%H) -ge 16 ]] && local before_midnight=true || local before_midnight=false
    in_window.sh $(map.sh routine.full_detach 21:30) 05:00 && local is_late=true || local is_late=false

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

    "$MY_SCRIPTS/lang/shell/battery.sh" 40

    printf 'Cort: '
    is 'cort' 2

    if map.sh -s ps.off; then
        echo "is off" | to_color.sh yellow
    fi

    # conditional displays ----------------------------------------------------------- #

    if ! $is_late && ! map.sh -s done.excuse; then
        echo "Do excuse practice"
    fi

    if ! $is_late && map.sh -s ps.off; then
        a '#b retrospective - off @tod'
    fi

    if map.sh -s 's.low_sleep'; then
        echo "Turn off alarm? - sleepy"
    fi

    # Handle snow
    if [[ $month -ge 11 || $month -le 2 ]]; then
        local forecast=$(weather)

        if echo $forecast | grep -q "snow"; then
            echo "$forecast"
            if ask "Add ear plugs? - snow"; then 
                a "ear plugs #b"
            fi
        fi
    fi

    # Handle temperature
    if [[ $month -ge 5 && $month -le 9 ]]; then
        local temp=$(loc -S sens temp)
        if [[ -n $temp ]]; then
            if (( $temp > 23 )); then
                echo "open window & rm curtains - ( $temp > 23°C )"
            elif (( $temp > 21 )); then
                echo "open window - ( $temp > 21°C )"
            fi
        fi
    fi
    
    if [[ $(date +"%m") -gt 5 && $(date +"%m") -le 8 && $(date +%H) -le 21 ]] && is_home; then # Is Jun, Jul or Aug
        echo "optimize melatonin - summer"
    fi

    if [[ $(date +%u) -eq 7 ]] && map.sh -s ps.off; then
        if $is_late; then
            echo "LOG #week"
        else
            a "**log week** #b"
        fi
    fi

    # manual track ------------------------------------------------- #

    echo

    if $before_midnight; then
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
            a "tv $tv_min"
        fi
    fi

    if [[ "$(map.sh s.gym_ago)" -ge 4 ]] && ! map.sh -s 's.sick' && ! $is_late; then
        leverage 'no_gym'
    fi

    # auto track ------------------------------------------------- #

    $before_midnight && (eve_track &)
    a '#tmp done ; detach'

    # display main ----------------------------------------------- #

    clear
    ! $is_late && eve_extra "$tv_min"

    ob eve

    "$HOME/.dotfiles/scripts/lang/shell/battery.sh" 50
    ob "p/auto/state eve act.md" | state_switch.sh

    # flight mode ------------------------------------------------ #

    if [[ ! " $@ " == *" -F "* ]]; then
        read
        short phondo "flight mode"
        dnd 1
    fi

    # other ------------------------------------------------------------ #

    local load_res=$(is -v "load" 1)
    if [[ "$load_res" -gt 6 ]]; then
        a "#b :p load - %% $load_res %% "
    fi

    later

    if ! $is_late && ! map.sh -s ps.off && is_home; then
        ask "Do wind-down activity later instead?" && a "#b [[detach]]"
    fi

    a '#done detach'
}


function bedtime {
    map.sh set done.bedtime true
    ( bedtime_extra & ) 2>/dev/null

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

    # display seasonal -------------------------------------------------------------------- #

    local month=$(date +%m)
    if [[ "$month" == "03" || "$month" == "04" || "$month" == "05" ]]; then
        echo "earbuds - spring"
    elif [[ $(date +%a) == (Fri|Sat) ]]; then
        echo "earplugs - weekend"
    elif is_orust; then
        echo "earplugs - orust"
    fi

    if [[ $month -le 2 || $month -ge 9 ]]; then
        echo "have warm clothes near"
        echo "scarf?"
    elif [[ $month -ge 4 && $month -le 5 ]]; then
        echo 'USE eye mask'
    
        local temp=$(loc -S sens/temp)
        if [[ -n $temp ]] && (( $temp > 21 )); then
            echo "USE fan - $temp > 21°C"

            if (( $temp > 22 )); then
                echo "cold pad UNDER pillow - $temp > 22°C"
            fi
        fi
    fi

    if [[ $(map s.sleep_delay) -ge 90 ]]; then
        echo "sleep somewhere different - sleep delay"
    fi

    # general ------------------------------------------------------------ #

    ob "state bedtime" | state_switch.sh
    ob bedtime

    # [[ $(ob p | lines) -le 2 ]] && plan

    a '#done bedtime'

    # shut down ------------------------------------------------------------------ #

    if is_home --not-offline && ! map.sh -s opt.reachable && ask "Set flight mode on phone?"; then
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
