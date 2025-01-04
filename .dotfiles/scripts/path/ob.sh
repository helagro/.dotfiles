input=$(echo "$*" | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')
vault="$HOME/vault"

(
    bat -P "$vault/i/$input.md" 2>/dev/null ||
        bat -P "$vault/p/$input.md" 2>/dev/null ||
        bat -P "$vault/tmp/$input.md" 2>/dev/null ||
        bat -P "$vault/_/log/$input.md" 2>/dev/null ||
        bat -P "$vault/$input.md" 2>/dev/null
) || exit 1
