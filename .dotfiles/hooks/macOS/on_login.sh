if [ $# -eq 0 ]; then
    echo "Waiting..."
    sleep 45
fi

MY_SCRIPTS="$HOME/.dotfiles/scripts"

function log_login {
    cat | $MY_SCRIPTS/lang/shell/utils/log.sh -sof on_login
}

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "\n----- RAN on_login.sh AT ($dt) -----\n" | log_login
echo "Running..."

# --------------------------- OTHER -------------------------- #

nohup "look_away" 2>&1 | $MY_SCRIPTS/lang/shell/utils/log.sh -sf break &

# ------------------------- ARCHIVER ------------------------- #

echo "   archiver" | log_login
$HOME/Documents/archiver-go/build/macOS 2>&1 | log_login

# ------------------------- APP LIST ------------------------- #

echo "   list_app" | log_login
cd "$MY_SCRIPTS/lang/shell" && ./list_app.sh 2>&1 | log_login

# ------------------------ BREW STUFF ------------------------ #

brew cleanup 2>&1 | log_login
