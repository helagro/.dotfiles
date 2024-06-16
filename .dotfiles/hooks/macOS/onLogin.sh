if [ $# -eq 0 ]; then
    echo "Waiting..."
    sleep 120
fi

LOG_FILE="$HOME/.dotfiles/data/onLogin.log"

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "\n----- RAN on_login.sh AT ($dt) -----\n" >>$LOG_FILE
echo "Running..."

# ------------------------- ARCHIVER ------------------------- #

echo "   archiver" | tee -a $LOG_FILE
cd "/Users/h/Documents/archiver/" && python3 main.py do >>$LOG_FILE

# ------------------------- APP LIST ------------------------- #

echo "   listApp" | tee -a $LOG_FILE
cd "$HOME/.dotfiles/scripts/path" && ./listApp.sh >>$LOG_FILE

# ------------------------ BREW STUFF ------------------------ #

brew upgrade >>$LOG_FILE
brew cleanup >>$LOG_FILE

# --------------------------- OTHER -------------------------- #

nohup "$HOME/Documents/break-timer/main" >>$LOG_FILE 2>&1 &
