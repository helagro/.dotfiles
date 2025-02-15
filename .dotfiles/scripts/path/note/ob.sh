if $HOME/.dotfiles/scripts/lang/shell/is_help.sh $*; then
    printf 'Usage: ob [-e] <note>\n'
    exit 0
fi

if [[ "$1" == "-e" ]]; then
    shift
    function action {
        if [ -e "$1" ]; then
            echo "Found \"$1\""
            nvim "$1"
            return 0
        else
            return 1
        fi
    }
else
    function action {
        bat -P "$1"
    }
fi

if [[ $1 != *"/in.md" ]]; then
    ob.sh _/local/in.md | grep -E "#$1(\s|$)" | sed "s/\\\#$1 *//g" 2>/dev/null
fi

# Parses arguments, expands cammel case, and removes .md extension
input=$(echo "$*" | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g' | sed 's/\.md$//g' 2>/dev/null)
vault="$HOME/vault" # Can't use exported, called by break timer

(
    action "$vault/i/$input.md" 2>/dev/null ||
        action "$vault/p/$input.md" 2>/dev/null ||
        action "$vault/tmp/$input.md" 2>/dev/null ||
        action "$vault/_/log/$input.md" 2>/dev/null ||
        action "$vault/$input.md" 2>/dev/null
) || exit 1
