#!/bin/zsh
setopt null_glob

# =========================== HELP =========================== #

if $HOME/.dotfiles/scripts/lang/shell/is_help.sh $*; then
    printf 'Usage: ob [-e] [--note-only] <note>\n'
    exit 0
fi

# =============================== INPUT PARSING ============================== #

if [[ $1 == '--note-only' ]]; then
    note_only=true
    shift
else
    note_only=false
fi

note_path="$*"

# ==================== FUNCTION SELECTION ==================== #

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
        [[ $1 =~ '_SRC|_RES' ]] && exit 1

        "$HOME/.dotfiles/scripts/path/utils/rat.sh" -P "$1"
    }
fi

function main {

    if [[ $1 != *"/in.md" ]] && ! $note_only; then
        # Looks in in.md ; looks for $note_path ; removes # ; colors yellow
        main _/local/in.md | \
            grep -E "#$1(\s|$)" | \
            sed "s|\\\#$1 *||g" | \
            $HOME/.dotfiles/scripts/path/utils/to_color.sh yellow 2>/dev/null
    fi

    # Parses arguments, and removes .md extension
    input=$(echo "$1" | sed 's/\.md$//g' 2>/dev/null)

    vault="$HOME/vault" # Can't use exported, called by break timer

    if [[ -d $vault ]]; then
        {
            action $vault/i/$input.md 2>/dev/null ||
                action "$vault/p/$input.md" 2>/dev/null ||
                action "$vault/_/log/$input.md" 2>/dev/null ||
                action "$vault/$input.md" 2>/dev/null ||
                action "$vault/tmp/$input.md" 2>/dev/null ||

                # Globbed
                action $vault/i/*/$input.md 2>/dev/null ||
                action $vault/p/*/$input.md 2>/dev/null ||
                action $vault/_/log/*/$input.md 2>/dev/null
        } || {
            echo "File not found" >&2
            exit 1
        }
    else
        echo "Local vault not found" >&2
        curl -s "https://raw.githubusercontent.com/helagro/notes/refs/heads/main/$input.md"
    fi
}

main "$note_path"
