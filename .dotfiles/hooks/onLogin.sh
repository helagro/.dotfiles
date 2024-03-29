echo "Waiting..."
# sleep 120

LOG_FILE="/Users/h/.dotfiles/data/onLogin.log"

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "----- Running on_login.sh ($dt) -----\n" >>$LOG_FILE
echo "Running..."

# ------------------------- ARCHIVER ------------------------- #

echo "   archiver" | tee -a $LOG_FILE
cd "/Users/h/Documents/archiver/" && python3 main.py do >>$LOG_FILE

# ------------------------- APP LIST ------------------------- #

echo "   listApp" | tee -a $LOG_FILE
cd "/Users/h/Documents/scripts/macOS/functions" && ./listApp.sh >>$LOG_FILE
