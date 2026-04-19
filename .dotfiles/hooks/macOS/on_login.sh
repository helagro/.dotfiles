MY_SCRIPTS="$HOME/.dotfiles/scripts"

function log_login {
    cat | $MY_SCRIPTS/lang/shell/utils/log.sh -sof on_login
}

# =================================== DELAY ================================== #

if [ $# -eq 0 ]; then
    echo "Waiting..."
    sleep 45
fi

# ================================== LOGGING ================================= #

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "\n----- RAN on_login.sh AT ($dt) -----\n" | log_login
echo "Running..."

# =================================== MAIN =================================== #

{
    # state ---------------------------------------------------------------------- #

    $MY_SCRIPTS/path/state/map.sh set done.boot 1 2>&1 

    # ------------------------- ARCHIVER ------------------------- #

    echo "   archiver" 
    $HOME/Documents/archiver-go/build/macOS 2>&1 

    # ------------------------- APP LIST ------------------------- #

    echo "   list_app"
    cd "$MY_SCRIPTS/lang/shell" && ./list_app.sh 2>&1

    # ------------------------ BREW STUFF ------------------------ #

    brew cleanup 2>&1
} | log_login

