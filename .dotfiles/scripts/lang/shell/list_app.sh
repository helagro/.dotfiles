# ------------------------- LIST APPS ------------------------ #

function list_apps() {
    ls /Applications
    ls $HOME/Applications
}

apps=""
while IFS= read -r line; do
    apps=$(echo "$apps $line ;" | tr -d '\n')
done <<<"$(list_apps)"

$HOME/.dotfiles/scripts/path/task/a.sh "#apps $apps"

# ------------------------- LIST BREW ------------------------ #

function store_brew() {
    while IFS= read -r line; do
        echo "brew install \"$line\" -q" >>$HOME/.dotfiles/setup/macOS/brewPkgs.sh
    done
}

echo "# Leaves" >$HOME/.dotfiles/setup/macOS/brewPkgs.sh
brew leaves | store_brew
echo "# Casks" >>$HOME/.dotfiles/setup/macOS/brewPkgs.sh
brew list --cask | store_brew
