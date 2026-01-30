#!/bin/zsh

# NOTE - Items must end with a comma, even last one
# NOTE - Used by server-app
export DISABLED_TD_APP_ITEMS="---,ob,null,"

alias glo="tl.sh"

# ================================= FUNCTIONS ================================ #

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

# activity ------------------------------------------------------------------- #

function act {

    # initializations ------------------------------------------------------------ #

    local full_input="$*"
    local project=''
    local activity_name=""
    local important_flag="-i"
    local do_local=true

    local focus_flag="-f"
    local max_duration="50:00"

    # calc connectivity ---------------------------------------------------------- #
    
    if ping -c1 -t1 8.8.8.8 &>/dev/null; then
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

    # handle specific activities ------------------------------------------------- #

    if [[ $project == "study" || $project == "p1" ]]; then
        activity_name="main"
    elif [[ $project == "sys" ]]; then
        if [[ "$full_input" != *'-d '* ]]; then
            echo "Custom duration required"
            return 1
        fi
        do_sys
    elif [[ $activity_name == "eat" ]]; then
        eat
        return
    fi
    
    # handle connectivity -------------------------------------------------------- #

    if $online; then
        tgs "$project" "$activity_name"

        if $do_local && in_window.sh 7:00 $(map.sh routine.full_detach 21:30); then
            (loc start &) >/dev/null 2>&1
        fi
    fi

    # handle focus -------------------------------------------------------------- #

    if $was_home; then
        local prev_focus=$(short get_focus)
        [[ -n $prev_focus ]] && focus_flag=""
    fi

    # run activity --------------------------------------------------------------- #

    sw $important_flag $focus_flag -a "$activity_name" $max_duration
    date +"%Y-%m-%d %H:%M:%S" | to_color.sh blue

    if $online; then
        toggl stop
        (loc stop &) >/dev/null 2>&1
    fi

    # break reminder ------------------------------------------------------------- #

    if [[ "$activity_name" == "main" ]]; then
        if ! map.sh -s s.headache && $was_home; then
            local break_len
            vared -p "Break Length (minutes): " -c break_len
            if [[ -n "$break_len" && "$break_len" != "0" ]]; then
                short -s timer "$break_len:00"
            fi
        fi
    fi
}


function exit_if_empty {
    local input=$(tee /dev/tty)

    if [[ -n "$input" ]]; then
        echo "$input"
    else
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

    # Handle workout types
    local cardio_types=("cardio" "floorball" "run" "badminton" "tennis" "bike")
    local type="$1"
    if [[ -z $type ]]; then
        vared -p "Workout type: " -c type
        [[ -z $type ]] && return 1
    fi

    # Track evening workouts
    if $is_recent_workout && in_window.sh 18:00 23:50; then
        a "t gym_eve #u"
    fi

    # Track cardio
    if [[ -n ${(M)cardio_types:#$type} ]]; then
        if $is_recent_workout; then
            a "t cardio #u"
        else
            a "$workout_time t cardio #u"
        fi

        echo "tracked cardio"
    fi

    local duration
    vared -p "Duration minutes (empty for start): " -c duration
    if $is_recent_workout && [[ -z $duration ]]; then

        # Show relevant note
        local types_with_notes=("floorball" "tennis" "bike")
        if [[ -n ${(M)types_with_notes:#$type} ]]; then
            obc "$type"
        elif [[ $type == "run" ]]; then
            obc "running"
        elif [[ -z ${(M)cardio_types:#$type} && $type != "exorita" ]]; then
            local is_probably_gym=true
            obc "gym"
        fi

        # Track and time
        local start_time=$(date +%s)
        act exor -n "$type" -D
        local end_time=$(date +%s)

        # Set duration
        duration=$(( (end_time - start_time) / 60 ))
        vared -p "Duration minutes: " -c duration

        if [[ -n $is_probably_gym ]]; then
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

        is_home && echo "Wash hands"
        echo "Upper pmr"
    fi

    if [[ -z $duration || $duration -lt 5 ]]; then
        echo "Invalid duration"
        return 1
    elif [[ $duration -gt 25 ]]; then
        map.sh set done.gym true
    fi

    if $is_recent_workout; then
        a "#xord $type ; $duration"
        a "workouts_min $duration ; workouts 1 #u"
    else
        a "$workout_time #u #xord $type ; $duration"
        a "$workout_time workouts_min $duration ; workouts 1 #u"
    fi

}

function pmr {
    local messages=("Feet" "Calves" "Thighs" "Torso" "Back" "Hands" "Biceps" "Triceps" "Shoulders & Neck" "Face")

    a 'mindwork 2 #u'
    trap 'print -n "\e[?25h"; return ; return' INT
    print -n "\e[?25l"

    for s in $messages; do
        printf "%s%*s" "$s" $((COLUMNS - ${#s})) "██"
        sleep 7

        print -n "\r\e[2K"
        sleep 7
    done

    print -n "\e[?25h"
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

function is {
    if [[ -z $* ]]; then
        echo "$is_output"
        return
    fi

    is_output=$(is.sh "$@")
    echo "$is_output" | rat.sh -pPl "json"
}

function is_m {
    local value=$(is main 1)

    map.sh set s.main $(printf '%s' $value | jq -r 'to_entries[1].value')
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
        later 'vared -c s && a "$s - sunlight #p"'
    fi

    if in_window.sh 20:00 13:00 && ! (echo "$b" | grep -q @bigb); then
        vared -p "big break: " -c item
        [[ -n $item ]] && a "@bigb $item #p"
        item=""
    fi

    if in_window.sh 18:00 7:00 && ! (echo "$b" | grep -q @start); then
        vared -p "start: " -c item
        [[ -n $item ]] && a "@start $item #p"
        item=""
    fi

    if ! $was_home && ! (echo "$b" | grep -q @return); then
        vared -p "return: " -c item
        [[ -n $item ]] && a "@return $item #p #b"
        item=""
    fi 

    if $was_home || ask "Do full planning?"; then
        vared -p "risk: " -c item
        while [[ -n $item && $item != "q" ]]; do
            [[ -n $item ]] && a "$item #risk"
            item=""
            vared -p "risk: " -c item
        done 
    fi

    vared -p "plan: " -c item
    while [[ -n $item && $item != "q" ]]; do
        [[ -n $item ]] && a "$item #p"
        item=""
        vared -p "plan: " -c item
    done
}

function plot {
    if [[ -p /dev/stdin ]]; then
        local input=$(cat)
        (nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$input" "$1" >/dev/null &)
        # conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$input" "$1"
    else
        (nohup conda run -n main --live-stream python3 "$MY_SCRIPTS/lang/python/plot_json.py" "$*" "$1" >/dev/null &)
    fi
}

function to_days {
    cat | jq -r 'to_entries | map("\(.key) \(.value)") | .[]' | while read the_date value; do
        weekday=$(date -j -f "%Y-%m-%d" $the_date +"%a")
        echo "{\"$weekday\": $value}"
    done | jq -s 'add' | rat.sh -pl json
}

function isl {
    is plainl $2 | grep $1 | while read attribute; do
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
    local tasks=$(echo "$content" | awk '/----/ {found = NR; next} NR > found')

    if [[ $? -eq 0 ]]; then
        if $do_add; then
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

    ob "$file" | python3 $MY_SCRIPTS/lang/python/ob_filter.py "$@" | rat.sh -Pl "$lang" --file-name "$file"
}

# Day Length
function dale {
    local num='0'
    [[ -n $1 ]] && num="$1"
    cat | grep -F $(day $num) | lines
}

function ob {
    set -- $($MY_SCRIPTS/lang/shell/expand_args.sh $*)

    ob.sh $*
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

function tundo {
    if ping -c 1 -t 1 8.8.8.8 &>/dev/null; then
        local N=$1
        tdls -p | tac | tail -n +$((N+1)) | in.sh
    else
        vim "$HOME/.dotfiles/tmp/a.txt"
    fi
}

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
        (
            (
                if command -v a.sh >/dev/null 2>&1; then
                    nohup a.sh "$*" &>/dev/null &
                else
                    echo "FAILED TO ADD: '$*' - a.sh not found"
                fi
            ) &
        )
    fi
}

function tdu {
    if $MY_SCRIPTS/lang/shell/is_help.sh $*; then
        echo "tdu <update> <id>..."
        return 0
    fi

    local update=$1
    shift

    for id in "$@"; do
        local content_line=$(td show $id | grep Content | cut -d' ' -f2-)

        a "$content_line" "$update"
        tdc $id
    done
}

function tdc {
    ping -c 1 -t 1 8.8.8.8 &>/dev/null
    local ping_exit_code=$?
    if [[ $ping_exit_code != 0 ]]; then
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

            if [[ $ping_exit_code == 0 ]]; then # If is online
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