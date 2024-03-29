echo "Waiting..."
sleep 120

cd "/Users/h/Documents/scripts/"
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "\n==== Running on_login.sh ($dt) =====" >>"/Users/h/Documents/scripts/main.log"
echo "Running..."

# ------------------------- ARCHIVER ------------------------- #

echo "   archiver" | tee -a "/Users/h/Documents/scripts/main.log"
cd "/Users/h/Documents/archiver/" && python3 main.py do >>"/Users/h/Documents/scripts/main.log"

# ------------------------ TODOIST APP ----------------------- #

echo "   todoist-obsidian sync" | tee -a "/Users/h/Documents/scripts/main.log"
cd "/Users/h/Documents/todoist-app" && nohup npm run start &
>>"/Users/h/Documents/scripts/main.log"

# ------------------------- APP LIST ------------------------- #

echo "   listApp" | tee -a "/Users/h/Documents/scripts/main.log"
cd "/Users/h/Documents/scripts/macOS/functions" && ./listApp.sh >>"/Users/h/Documents/scripts/main.log"
