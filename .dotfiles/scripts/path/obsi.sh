vault="/Users/h/Dropbox/Apps/remotely-save/vault"
doc="/Users/h/Documents"
scripts="$doc/scripts/macOS"

[[ -z "$1" ]] && 1="0"

find $vault/i -type f -name "*.md" | while IFS= read -r line; do
    items=$($scripts/build/obsi "$line")

    if [[ $items -ge $1 ]]; then
        echo $line : $items
    fi
done
