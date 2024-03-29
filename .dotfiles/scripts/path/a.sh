a75h=uyE1bf9kt60kYj
resCode=$(curl -s -b "a75h=$a75h" -o /dev/null -w "%{http_code}" -X POST -d "$@" https://helagro.se/td-app)

if [ "$resCode" -eq 200 ]; then
    exit
fi

if ! todoist q "$@"; then
    osascript -e "tell application \"NotificationCenter\" to display notification \"'$@'\" with title \"Could not add\""
fi
