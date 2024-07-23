# ------------------------- LIST APPS ------------------------ #

function list_apps() {
    ls /Applications
    ls $HOME/Applications
}

dt=$(date '+%Y-%m-%d')
list_apps >"$HOME/Downloads/apps ($dt).md"

# ------------------------- LIST BREW ------------------------ #

function store_brew() {
    while IFS= read -r line; do
        echo "brew install \"$line\"" >>$HOME/.dotfiles/setup/macOS/brewPkgs.sh
    done
}

echo "" >$HOME/.dotfiles/setup/macOS/brewPkgs.sh
brew leaves | store_brew
brew list --cask | store_brew
