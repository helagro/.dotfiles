function on_tab {
    clear
}

# =================================== LATER ================================== #

function later { python3 $HOME/.dotfiles/scripts/lang/python/later.py "$@"; }
function _later_completions {
    _arguments '*:command:_command_names'
}
compdef _later_completions later

function latera { later "a \"$*\""; }
function latero {
    local url="$*"
    if [[ $url != http* ]]; then
        url="https://$url"
    fi

    later "open \"$url\""
}

# ================================== TODOIST ================================= #

alias td="todoist"
alias tdl="$MY_SCRIPTS/lang/shell/task/tdl.sh"
alias tdi="tdl '(tod|od|p1)'"
alias tundo="tdls :inbox | tac | in.sh "

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

function tdcp {
    if [ -n "$1" ]; then
        last_todoist_project="$1"
    fi

    if [ "$2" = "s" ]; then
        td s
    fi

    local id_list=($(tdl "$last_todoist_project" | peco | awk '{print $1}' ORS=' ' | sed 's/\x1b\[[0-9;]*m//g'))
    tdc "${id_list[@]}"
    echo "${id_list[@]}"
}

function tdup {
    # ARGS: update, project?, s?

    if [ -n "$2" ]; then
        last_todoist_project="$2"
    fi

    if [ "$3" = "s" ]; then
        td s
    fi

    local id_list=($(tdl "$last_todoist_project" | peco | awk '{print $1}' ORS=' ' | sed 's/\x1b\[[0-9;]*m//g'))
    tdu "$last_todoist_project $1" "${id_list[@]}"
    echo "${id_list[@]}"
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