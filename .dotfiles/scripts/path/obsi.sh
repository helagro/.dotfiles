vault="/Users/h/Dropbox/Apps/remotely-save/vault"
scripts="$HOME/.dotfiles/scripts/"

[[ -z "$1" ]] && 1="0"

find $vault/i -maxdepth 1 -type f -name "*.md" | while IFS= read -r line; do
    items=$($scripts/obsi "$line")

    if [[ $items -ge $1 ]]; then
        echo $line : $items
    fi
done
