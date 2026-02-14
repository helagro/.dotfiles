
function tdxtract {
    local content=$2

    if [[ $1 == "id" ]]; then
        printf "%s" "$content" | grep -Eo '^[[:alnum:]]+'                       
            
    elif [[ $1 == "no_id" ]]; then
        echo "$content" | sed -E 's/^[[:alnum:]]+[[:space:]]+//' | de_space
    else
        echo "Unknown extract type: $1" 1>&2
        return 1
    fi
}

function add_under {
    if [ "$1" == "-h" ]; then
        echo "Usage: td.sh add_under <parent ID> <child's content>"
        exit 0
    fi

    parent=$1
    shift
    content="$@"

    curl -sS "https://api.todoist.com/rest/v2/tasks" \
        -X POST \
        --data "{\"content\": \"$content\", \"parent_id\": \"$parent\"}" \
        -H "Content-Type: application/json" \
        -H "X-Request-Id: $(uuidgen)" \
        -H "Authorization: Bearer $TODOIST_TOKEN" >/dev/null
}

function de_space {
    cat | 
        tr -s '[:space:]' ' ' | 
        tr -s '  ' ' ' |
        sed 's/^ *//' | 
        sed 's/ *$//' 
}

# =================================== ENTRY ================================== #

fun="$1"
shift

if [[ "$fun" == "x" ]]; then
    tdxtract "$@"
elif [[ "$fun" == "au" ]]; then
    add_under "$@"
elif [[ $fun == "s" ]]; then
    de_space
else
    echo "Unknown function: $fun" >&2
    exit 1
fi