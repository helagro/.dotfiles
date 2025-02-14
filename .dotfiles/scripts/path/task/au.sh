# Add under

if [ "$1" == "-h" ]; then
    echo "Usage: au.sh <parent ID> <child's content>"
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
