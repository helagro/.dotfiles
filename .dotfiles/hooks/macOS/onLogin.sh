if [ $# -eq 0 ]; then
    echo "Waiting..."
    sleep 120
fi

LOG_FILE="$HOME/.dotfiles/data/onLogin.log"
BREAK_LOG_FILE="$HOME/.dotfiles/data/break.log"

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "\n----- RAN on_login.sh AT ($dt) -----\n" >>$LOG_FILE
echo "Running..."

# ------------------------- ARCHIVER ------------------------- #

echo "   archiver" | tee -a $LOG_FILE
$HOME/Documents/archiver-go/archiver-go >>$LOG_FILE

# ------------------------- APP LIST ------------------------- #

echo "   list_app" | tee -a $LOG_FILE
cd "$HOME/.dotfiles/scripts/path" && ./list_app.sh >>$LOG_FILE

# ------------------------ BREW STUFF ------------------------ #

brew upgrade >>$LOG_FILE
brew cleanup >>$LOG_FILE

# --------------------------- OTHER -------------------------- #

nohup "$HOME/Documents/break-timer/main" >>$BREAK_LOG_FILE 2>&1 &
