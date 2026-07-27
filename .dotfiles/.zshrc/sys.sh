#!/bin/zsh

alias glo="tl.sh"
alias map="map.sh"

dawn_start='04:00'
day_start='12:00'
eve_start='18:00'
eve_end='01:00'
ashr="$HOME/.dotfiles/scripts/secret/ash_remind.sh"

# ================================= FUNCTIONS ================================ #

function is_dawn { in_window.sh $dawn_start $day_start; }
function is_day { in_window.sh $day_start $eve_start; }
function is_eve { in_window.sh $eve_start $eve_end; }

alias is_summery='test "$(date +%m)" -ge 5 -a "$(date +%m)" -le 9'
alias is_wintery='test "$(date +%m)" -ge 11 -o "$(date +%m)" -le 2'


function is_occupied {
    local current_activity=$(map.sh -m act.current)

    [[ $current_activity =~ "^(study|p1|mind)$" ]]
}


function blind {
    local input=$(cat)
    local lines=("${(@f)input}")   # split on newlines
    local line_nr=1

    while true; do
        say -v samantha -r 270 -- "${lines[$line_nr]}"

        printf "(n)ext (p)revious (c)urrent (q)uit: " > /dev/tty
        read -k 1 choice </dev/tty
        echo >/dev/tty

        case "$choice" in
            n)
                line_nr=$((line_nr + 1))
            ;;
            p)
                line_nr=$((line_nr - 1))
            ;;
            q)
                break
            ;;
        esac
    done
}


function addo {
    pushd $VAULT > /dev/null
    git add "$1.md"
    popd > /dev/null
}


function ect {
    pushd $DEV/config > /dev/null
    vd public/server-app/act.tsv
    ask "Deploy to Firebase?" && firebase deploy
    popd > /dev/null
}


function act {

    # initializations ------------------------------------------------------------ #

    activity_name=""
    local full_input="$*"
    local project=''
    local important_flag="-i"

    local do_local=true
    local should_block=true

    local max_duration="50:00"
    local duration_overridden=false

    map.sh -s opt.reachable && local focus_flag="" || local focus_flag="-f"
    in_window.sh 7:00 $(map routine.latest_dinner 20:00) && local is_day=true || local is_day=false

    # calc connectivity ---------------------------------------------------------- #
    
    if is_online; then
        local online=true
    else
        local online=false
        echo "[OFFLINE]" | to_color.sh red
    fi

    if ! $online || ! is_home; then
        local was_home=false

        max_duration=""
        focus_flag=""
    else
        local was_home=true
    fi

    # process arguments ---------------------------------------------------------- #

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -n | --name)
            activity_name="$2"
            shift 2
            ;;
        -d | --duration)
            max_duration="$2:00"
            duration_overridden=true
            shift 2
            ;;
        -D | --no-duration)
            max_duration=""
            shift 1
            ;;
        -F | --skip-focus)
            focus_flag=""
            shift 1
            ;;
        -f | --focus)
            focus_flag="-f"
            shift 1
            ;;
        -S | --continue-after-duration)
            important_flag=""
            shift 1
            ;;
        -L | --skip-local)
            do_local=false
            shift 1
            ;;
        *)
            project="$1"
            shift 1
            ;;
        esac
    done

    # print secondary info ------------------------------------------------------- #

    date +"%Y-%m-%d %H:%M:%S" | to_color.sh blue
    ( $was_home && act_extra "$activity_name" "$project" & )

    # handle specific activities ------------------------------------------------- #

    if [[ $project == "study" || $project == "p1" ]]; then
        activity_name="main"

        if [[ $project == "p1" ]]; then
            echo 'Main during' | to_color.sh cyan
        fi
    i
    elif [[ $project == "sys" ]]; then
        if ! $duration_overridden && ! map.sh -s ps.off; then
            echo "Custom duration required" | to_color.sh cyan
            return 1
        fi

        echo 'Medd during' | to_color.sh cyan
        should_block=false

    elif [[ $project == "exor" || $project == "mind" || $project == "mixed" || $project == "social" ]]; then
        if ! $duration_overridden; then
            max_duration=''
        fi

        if [[ $activity_name == 'medd' ]]; then
            do_meditation
            important_flag=''
        elif [[ $activity_name == 'walk' ]]; then
            ask 'cort 2.5?' && a 'cort 2.5 #u'
        fi

    elif [[ $project == "improve" ]]; then
        max_duration=''
        should_block=false

    elif [[ -z $project ]]; then
        max_duration=''
        should_block=false

        if [[ $activity_name == 'b' ]]; then
            echo 'Medd during' | to_color.sh cyan
        fi
    fi

    # handle connectivity -------------------------------------------------------- #

    if $online; then
        # toggl
        tgs "$project" "$activity_name"

        # local app
        if $do_local && in_window.sh 7:00 $(map routine.full_detach 21:30); then
            local start_param="?blocking=$($should_block && echo 1 || echo 0)"

            if (map -s s.headache || map -s s.eye || map -s s.stiff); then
                start_param="$start_param&alert_frequency=17"
            fi

            (
                loc "start$start_param" &
                if $is_day; then 
                    [[ $activity_name == 'main' ]] && loc dev colored color work &
                    [[ $activity_name == 'improve' ]] && loc dev colored color 55ff55 &
                fi
            ) >/dev/null 2>&1
        fi
    fi

    # handle focus -------------------------------------------------------------- #

    if $was_home; then
        local prev_focus=$(short get_focus)
        [[ -n $prev_focus ]] && focus_flag=""
    fi

    # run activity --------------------------------------------------------------- #

    if [[ -n $project ]]; then
        map -m set act.current "$project"
    else
        map -m set act.current "no project"
    fi

    sw $important_flag $focus_flag -a "$activity_name" $max_duration
    date +"%Y-%m-%d %H:%M:%S" | to_color.sh blue

    # stop activity -------------------------------------------------------------- #

    map -m set act.current null

    if $online; then
        (
            toggl stop || later 'toggl stop'
            loc stop &
            $is_day && loc "dev colored color chill" &
        ) >/dev/null 2>&1
    fi
}


function dnd {
    local mode do_phone=false do_wifi=false
    local was_on=$(map opt.dnd_on)

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -p | --phone)
            do_phone=true
            shift 1
            ;;
        -w | --wifi)
            do_wifi=true
            shift 1
            ;;
        -f | --focus)
            short -s focus "$2"
            sleep 2
            shift 2
            ;;
        *)
            mode="$1"
            shift 1
            ;;
        esac
    done

    if [[ ! -e /opt/homebrew/etc/blocky/config.yml ]]; then
        ln -s $HOME/.dotfiles/config/blocky.yml /opt/homebrew/etc/blocky/config.yml
    fi

    if [[ $mode == $was_on ]]; then
        return
    fi
    
    if [[ -z $mode ]]; then
        mode=$((1 - $was_on))
    fi

    if [[ $mode == 1 ]]; then
        if $do_phone; then
            short -s phondo 'flight mode'
            sleep 2
        fi

        if $do_wifi; then
            wifi off
        fi

        { 
            echo "block drop out quick from any to 17.0.0.0/8" | sudo pfctl -ef -
            sudo networksetup -setdnsservers Wi-Fi 127.0.0.1
            brew services restart blocky
        } >/dev/null 2>&1
        
        map.sh set opt.dnd_on 1
    else
        if $do_wifi; then
            wifi on
        fi

        {
            sudo pfctl -d
            sudo networksetup -setdnsservers Wi-Fi "Empty"
            brew services stop blocky
        } >/dev/null 2>&1

        map.sh set opt.dnd_on 0
    fi
}


# NOTE - Used by obsidian-extension
function exit_if_empty {
    local input=$(tee /dev/tty)

    if [[ -z "$input" ]]; then
        exit 0
    fi
}


function gym {
    local workout_time=$(date +"%Y-%m-%d %H:%M")

    # Track old workouts
    local is_recent_workout=true
    if [[ $1 == "-o" ]]; then
        is_recent_workout=false
        shift

        # Workout time
        workout_time=""
        vared -p "Workout time (freeform): " -c workout_time
        [[ -z $workout_time ]] && return 1
    fi

    # handle workout types ------------------------------------------------------- #

    local cardio_types=("cardio" "floorball" "run" "badminton" "tennis" "bike")
    local type="$1"
    if [[ -z $type ]]; then
        vared -p "Workout type: " -c type
        [[ -z $type ]] && return 1
    fi

    [[ $type == *'exorita'* ]] && local is_exorita=true || local is_exorita=false
    [[ -n ${(M)cardio_types:#$type} ]] && local is_cardio=true || local is_cardio=false 
    [[ $type == *'run'* ]] && local is_run=true || local is_run=false
    [[ $type == *'gym'* ]] && local is_gym=true || local is_gym=false

    # track specifics ------------------------------------------------------------ #

    if $is_recent_workout; then
        
        # Track workout for times
        if in_window.sh 18:00 23:50; then
            a "gym_eve 1 #u"
        elif in_window.sh 4:00 12:00; then
            a "gym_dawn 1 #u"
        fi

        # Track cardio
        if $is_cardio; then
            if $is_recent_workout; then
                a "cardio 1 #u"
            else
                a "$workout_time t cardio #u"
            fi

            echo "[tracked cardio]" | to_color.sh blue
        fi
    fi

    # take duration input -------------------------------------------------------- #

    local duration
    vared -p "Duration minutes (empty for start): " -c duration

    # run current workout -------------------------------------------------------- #

    if $is_recent_workout && [[ -z $duration ]]; then

        # Show warnings
        if map -s s.low_sleep && in_window.sh 07:00 14:00; then
            echo "WARN - Workout when tired, consider afternoon energy" | to_color.sh yellow
        fi

        # Show relevant note
        local types_with_notes=("floorball" "tennis" "bike")
        if [[ -n ${(M)types_with_notes:#$type} ]]; then
            obc "$type"
        elif [[ $type == *"run"* ]]; then
            obc "running"
            ask 'Continue?'
        elif $is_gym; then
            if map.sh -s s.weak; then
                obc "gym prob"
            else
                obc "gym"
            fi
        fi
        
        # Setup env
        if $is_exorita; then
            (loc dev bath lvl 130 &>/dev/null &) 
        fi

        # Track and time
        local start_time=$(date +%s)
        act exor -n "$type" -D
        local end_time=$(date +%s)

        # Set duration
        duration=$(( (end_time - start_time) / 60 ))
        vared -p "Duration minutes equation: " -c duration
        duration=$(echo "$duration" | bc)

        # Track time results    
        if $is_gym && ! map.sh -s ps.off; then
            local decomp
            vared -p "Decompress minutes: " -c decomp
            if [[ -n $decomp && $decomp -gt 0 ]]; then
                a "decomp $decomp #u"
            fi

            local main
            vared -p "Main minutes: " -c main
            if [[ -n $main && $main -gt 0 ]]; then
                a "main $main #u"
            fi
        fi

        # Restore physical environment
        if $is_exorita; then
            ({
                loc dev bath lvl 30
                sleep 0.5
                loc t bath
            }&) &>/dev/null
        fi

        # Print reminders
        is_home && ! $is_exorita && ! $is_run && echo "Wash hands"
        echo "Upper pmr"
    fi

    # handle duration ------------------------------------------------------------ #

    if [[ -z $duration || $duration -lt 5 ]]; then
        echo "Invalid duration"
        return 1
    elif [[ $duration -gt 25 ]]; then
        map.sh set done.gym true
    fi

    # final tracking -------------------------------------------------------------- #

    if $is_recent_workout; then
        a "c gym"
        a "#xord $type ; $duration"
        a "workouts_min $duration ; workouts 1 #u"
        map.sh set done.gym true

        # Track leg day
        if [[ "$type" == *"leg"* && $duration -ge 20 ]]; then
            a 't leg_day #u'
            map.sh set s.leg_day true
        fi
    else
        a "$workout_time c gym"
        a "$workout_time #u #xord $type ; $duration"
        a "$workout_time workouts_min $duration ; workouts 1 #u"
    fi
}


function pmr {
    local messages=("Feet" "Calves" "Thighs" "Torso" "Back" "Hands" "Biceps" "Triceps" "Shoulders & Neck" "Face")

    trap 'print -n "\e[?25h"; return ; return' INT
    print -n "\e[?25l"

    for s in $messages; do
        printf "%s%*s" "$s" $((COLUMNS - ${#s})) "██"
        sleep 7

        print -n "\r\e[2K"
        sleep 7
    done

    print -n "\e[?25h"
    a 'mindwork 2 #u'
    map.sh inc stat.pmr 1
}


function tgs {
    local project_name=$1

    if [[ -z $project_name ]]; then
        toggl start "$*"
        return
    elif [[ $project_name == 'none' ]]; then
        shift
        toggl start "$*"
        return
    else
        shift
    fi
    
    [[ -z $toggl_projects ]] && toggl_projects=$(toggl projects 2>/dev/null)
    local project_id=$(echo "$toggl_projects" | grep -F " $project_name" | awk '{print $1}')

    if [[ -n "$project_id" ]]; then
        toggl start -P "$project_id" "$*"
    else
        echo "Project not found" 1>&2
        return 1
    fi
}

# tracking ------------------------------------------------------------------- #

function group { python3 $MY_SCRIPTS/lang/python/group.py "$@" | rat.sh -pPl 'json'; }
function csv { conda run -n main python3 "$MY_SCRIPTS/lang/python/jsons_to_csv.py" $@ | rat.sh -pPl 'tsv'; }
alias is_mw='is main $(date +%u) | st sum | hm'


function is {
    is.sh "$@" | rat.sh -pPl "json"
}


function is_m {
    local value=$(is -v main 1)

    map.sh set s.main $(printf '%s' $value)
    echo $value | hm
}


function is_d {
    local value=$(is decomp 1)

    map.sh set s.decomp $(printf '%s' $value | jq -r 'to_entries[1].value')
    echo $value | hm
}


function plan {
    local item
    local b=$(ob b)
    is_home --guess-yes && local was_home=true || local was_home=false
    # load 

    if in_window.sh 20:00 15:00 && [[ $(date +"%m") -le 2 ]]; then # Is Jan or Feb
        later 'vared -c s && a "$s - reflection #p"'
    fi

    if in_window.sh 20:00 13:00 && ! (echo "$b" | grep -q @bigb); then
        vared -p "$(echo "big break: " | to_color.sh yellow)" -c item
        [[ -n $item ]] && a "@bigb $item #p"
        item=""
    fi

    if in_window.sh 18:00 7:00 && ! (echo "$b" | grep -q @start); then
        vared -p "$(echo "start: " | to_color.sh yellow)" -c item
        [[ -n $item ]] && a "@start $item #p"
        item=""
    fi

    if ! $was_home && ! (echo "$b" | grep -q @return) && ! map.sh -s s.away; then
        vared -p "$(echo "return: " | to_color.sh yellow)" -c item
        [[ -n $item ]] && a "@return $item #p #b"
        item=""
    fi 

    if { $was_home || map.sh -s s.away } || ask "Do full planning?"; then
        vared -p "$(echo "risk: " | to_color.sh yellow)" -c item
        while [[ -n $item && $item != "q" ]]; do
            [[ -n $item ]] && a "$item #risk"
            item=""
            vared -p "$(echo "risk: " | to_color.sh yellow)" -c item
        done 
    fi

    if [[ $(map.sh s.tv) -gt 120 ]]; then
        vared -p "$(echo "media: " | to_color.sh yellow)" -c item
        item=""
    fi

    if map.sh -s s.cardio; then
        vared -p "$(echo "energy: " | to_color.sh yellow)" -c item
        [[ -n $item ]] && a "@energy $item #p"
        item=""
    fi

    vared -p "$(echo "plan: " | to_color.sh yellow)" -c item
    while [[ -n $item && $item != "q" ]]; do
        [[ -n $item ]] && a "$item #p"
        item=""
        vared -p "$(echo "plan: " | to_color.sh yellow)" -c item
    done
}


function plot {
    if [[ -p /dev/stdin ]]; then
        local input=$(cat)
        (nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$1" "$input" >/dev/null &)
        # conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$input" "$1"
    else
        # (nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$@" >/dev/null &)
        conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "Plot" "$@" 
    fi
}


function to_days {
    cat | jq -r 'to_entries | map("\(.key) \(.value)") | .[]' | while read the_date value; do
        weekday=$(date -j -f "%Y-%m-%d" $the_date +"%a")
        echo "{\"$weekday\": $value}"
    done | jq -s 'add' | rat.sh -pl json
}


function isl {
    is plainlist $2 | grep $1 | while read attribute; do
        printf "$attribute "
    done
}


# obsidian ------------------------------------------------------------------- #

function do_now {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    local do_write=false
    local do_add=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help)
            echo "Usage: do_now [-w] <file_name>"
            echo "  -w: Overwrite the contents following '----'"
            return 0
            ;;
        -w | --write)
            do_write=true
            shift 1
            ;;
        -D | --do-not-add)
            do_add=false
            shift 1
            ;;
        *)
            local file_name="$VAULT/$1.md"
            shift
            ;;
        esac
    done

    if [[ ! -e "$file_name" ]]; then
        echo "$file_name does not exist"
        return 1
    fi

    local content=$(cat "$file_name")

    if [[ $? -eq 0 ]]; then
        if $do_add; then
            local tasks=$(echo "$content" | awk '/----/ {found = NR; next} NR > found' | state_switch.sh)

            echo "$tasks" | a
            echo "$tasks"
        fi

        if $do_write; then
            echo "$content" | awk '/----/ {exit} {print}' >"$file_name"
            echo "----" >>"$file_name"
        fi
    else
        echo "Error reading file: $file_name"
        return 1
    fi
}


function obc {
    local file="$1"
    shift
    local lang="markdown"

    if [[ "$*" == *"-l"* ]]; then
        lang="json"
    fi

    ob --note-only "$file" | python3 $MY_SCRIPTS/lang/python/ob_filter.py "$@" | rat.sh -Pl "$lang" --file-name "$file"
}


# Day Length
function dale {
    local num='0'
    [[ -n $1 ]] && num="$1"
    cat | grep -F $(day $num) | lines
}


function ob {
    ob.sh "$@"
}
function _ob_completions {
    _files -W $VAULT
    _files -W $VAULT/i
    _files -W $VAULT/p
    _files -W $VAULT/tmp
}
compdef _ob_completions ob


# todoist -------------------------------------------------------------------- #

alias td="todoist"
alias tdl="tdl.sh"
alias tdi="tdl '(tod|od|p1)'"

alias tds='(td s &)'
alias tdis='td s && tdi'
alias tdls='td s && tdl'


function a {
    if [ -z "$*" ]; then  # If no arguments passed
        if [ -t 0 ]; then # If terminal
            a_ui
        else # If piped
            # Read lines from pipe
            while read -r line; do
                line=$(echo "$line" | sed -e 's/^- \[ \] //' -e 's/^- //') # Remove checkboxes
                a "$line"
            done
        fi
    else # If arguments passed
        ({
            if command -v a.sh >/dev/null 2>&1; then
                nohup a.sh "$*" &>/dev/null &
            else
                echo "FAILED TO ADD: '$*' - a.sh not found"
            fi
        }&)
    fi
}


function tdc {
    is_online
    local is_online_exit_code=$?
    if [[ $is_online_exit_code != 0 ]]; then
        echo "[OFFLINE]"
    fi

    for arg in "$@"; do # For every arg
        for id in ${(z)arg}; do # For every id in the arg
            if [[ ${#id} -lt 4 ]]; then # If provided tdl index instead
                cat "$HOME/.dotfiles/tmp/tdl.txt" | while IFS= read -r line; do
                    if [[ $line == "($id)"* ]]; then # If tdl line matches
                        id=$(echo "$line" | awk '{print $2}')
                        echo "$line" >> "$HOME/.dotfiles/logs/tdc.log"
                        echo $line
                        break
                    fi
                done
            fi

            if [[ $is_online_exit_code == 0 ]]; then # If is online
                if command -v todoist >/dev/null 2>&1; then
                    (nohup todoist c "$id" >/dev/null 2>&1 &)
                else
                    curl -sX POST "https://api.todoist.com/rest/v2/tasks/$id/close" \
                        -H "Authorization: Bearer $TODOIST_TOKEN"
                fi
            else # If is offline
                later "tdc \"$id\""
            fi
        done
    done
}

