source "$HOME/.zshrc"

function main {
    dt=$(date '+%d/%m/%Y %H:%M:%S')
    echo "\n----- RAN daily.sh AT ($dt) -----\n"

    if [[ $(date +%u) -eq 7 ]]; then
        weekly 2>&1
    fi

    # tasks -------------------------------------------------------------------- #

    # archiver
    echo "--- archiver"
    $HOME/Documents/archiver-go/build/macOS 2>&1

    # list apps
    echo "--- list_app"
    cd "$MY_SCRIPTS/lang/shell" && ./list_app.sh 2>&1

    # add day tasks
    echo "--- add_day_tasks"
    do_now -w p/day 2>&1
}

function weekly {
    echo "Running weekly tasks..."

    local cleaned_done=$(obc done -F b | grep -v '^$')
    echo "$cleaned_done" > "$VAULT/_/log/done.md"
}

# ================================== HELPERS ================================= #

function log {
    cat | $MY_SCRIPTS/lang/shell/utils/log.sh -sof daily
}

# =================================== START ================================== #

main | log