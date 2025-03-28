#!/bin/zsh

set -- $($MY_SCRIPTS/lang/shell/expand_args.sh "$@")

do_output=false
do_stdin=false
file_name=""

# ================================ PARSE INPUT =============================== #

while [[ $# -gt 0 ]]; do
    case "$1" in
    -o | --output)
        do_output=true
        shift 1
        ;;
    -s | --stdin)
        do_stdin=true
        shift 1
        ;;
    -f | --file)
        file_name="$2"
        shift 2
        ;;
    -h | --help)
        printf 'Usage: log.sh [options...]  <log content>\n'
        printf " %-3s %-20s %s\n" "-o" "--output" "Output to stdout"
        printf " %-3s %-20s %s\n" "-s" "--stdin" "Read from stdin"
        printf " %-3s %-20s %s\n" "-h" "--help" "Show this help message"
        exit 0
        ;;
    *) break ;;
    esac
done

# ================================ SETUP FILE =============================== #

if [[ -z "$file_name" ]]; then
    echo "Missing file name" >&2
    exit 1
fi
file_path="$HOME/.dotfiles/logs/$file_name.log"

if [[ ! -e "$file_path" ]]; then
    touch "$file_path"
fi

# ================================ TRIM LOG FILE ================================ #

log_size=$(wc -l $file_path | awk '{print $1}')
excess=$(expr $log_size - 2000)

if [ $excess -gt 0 ]; then
    del_amt=$(expr $excess + 500)
    sed -i '' 1,$del_amt'd' $file_path
fi

# ================================ HANDLE LOG ================================ #

if $do_stdin; then
    if $do_output; then
        cat | tee -a $file_path
    else
        cat >>$file_path
    fi
else
    new_content="$*"

    echo "$new_content" >>$file_path
    if $do_output; then
        echo "$new_content"
    fi
fi
