source $HOME/.dotfiles/.zshrc/secrets.sh
resCode=$(curl -s -b "a75h=$A75H" -o /dev/null -w "%{http_code}" -X POST -d "$@" $TDA_URL)

if [ "$resCode" -eq 200 ]; then
    exit
fi

if ! todoist q "$@"; then
    osascript -e "tell application \"NotificationCenter\" to display notification \"'$@'\" with title \"Could not add\""
    echo "a WITH '$@' FAILED" >>$HOME/.dotfiles/data/a.log
fi
