if [ $# -eq 0 ]; then
    echo "Waiting..."
    sleep 120
fi

MY_SCRIPTS="$HOME/.dotfiles/scripts"

function log_login {
    cat | $MY_SCRIPTS/lang/shell/utils/log.sh -o on_login
}

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "\n----- RAN on_login.sh AT ($dt) -----\n" | log_login
echo "Running..."

# ------------------------- ARCHIVER ------------------------- #

echo "   archiver" | log_login
$HOME/Documents/archiver-go/build/macOS | log_login

# ------------------------- APP LIST ------------------------- #

echo "   list_app" | log_login
cd "$MY_SCRIPTS/lang/shell" && ./list_app.sh | log_login

# ------------------------ BREW STUFF ------------------------ #

brew cleanup | log_login

# --------------------------- OTHER -------------------------- #

nohup "$HOME/Documents/break-timer/main" | $MY_SCRIPTS/lang/shell/utils/log.sh break &
