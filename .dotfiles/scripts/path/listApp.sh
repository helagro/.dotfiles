# ------------------------- LIST APPS ------------------------ #

function listApps() {
    ls /Applications
    ls $HOME/Applications
}

dt=$(date '+%Y-%m-%d')
listApps >"$HOME/Downloads/apps ($dt).md"

# ------------------------- LIST BREW ------------------------ #

echo "" >$HOME/.dotfiles/setup/macOS/brewPkgs.sh
brew list | while IFS= read -r line; do
    echo "brew install \"$line\"" >>$HOME/.dotfiles/setup/macOS/brewPkgs.sh
done
