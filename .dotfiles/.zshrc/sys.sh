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
    local project=''
    local max_duration="50:00"
    local focus_flag="-f"
    local activity_name=""
    local important_flag="-i"

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
        *)
            project="$1"
            shift 1
            ;;
        esac
    done

    date +"%Y-%m-%d %H:%M:%S" | to_color.sh blue

    if ping -c1 -t1 8.8.8.8 &>/dev/null; then
        local online=true
    else
        local online=false
        echo "[OFFLINE]" | to_color.sh red
    fi

    if [[ $project == "sys" ]]; then
        # do_sys
        # [[ -n $override_act_duration ]] && max_duration="$override_act_duration:00"
    elif [[ $activity_name == "eat" ]]; then
        eat
        return
    fi
    
    local prev_focus=$(short get_focus)
    [[ -n $prev_focus ]] && focus_flag=""

    $online && tgs "$project" "$activity_name"

    [[ $(short is_home) == *"false"* ]] && focus_flag=""
    sw $important_flag $focus_flag -a "$activity_name" $max_duration

    if $online; then
        toggl stop
        (loc stop &) >/dev/null 2>&1
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
    (loc start &) >/dev/null 2>&1

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

function hm { python3 $MY_SCRIPTS/lang/python/hm.py "$@" | rat.sh -pPl 'json'; }
function group { python3 $MY_SCRIPTS/lang/python/group.py "$@" | rat.sh -pPl 'json'; }
function csv { conda run -n main python3 "$MY_SCRIPTS/lang/python/jsons_to_csv.py" $@ | rat.sh -pPl 'tsv'; }
alias is="is.sh"

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

function loc {
    local do_new_line=true
    local do_silent=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -n | --no-new-line)
            do_new_line=false
            shift 1
            ;;
        -s | --do-silent)
            do_silent=true
            shift 1
            ;;
        *)
            break
            ;;
        esac
    done

    local params="${(j:/:)@}"
    local result=$(curl -sS --connect-timeout 2 "$LOCAL_SERVER_IP:8004/$params")

    if [[ $? -ne 0 ]]; then
        result='{"error": "Could not connect to local server"}'
        return 1
    fi

    if $do_silent; then
        return 0
    fi

    if $do_new_line; then
        echo "$result" | rat.sh -pPl "json"
    else
        echo -n "$result" | rat.sh -pPl "json"
    fi
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
    local N=$1
    tdls -p | tac | tail -n +$((N+1)) | in.sh
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