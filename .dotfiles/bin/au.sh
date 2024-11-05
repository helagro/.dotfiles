parent=$1
shift
content="$@"

curl -sS "https://api.todoist.com/rest/v2/tasks" \
    -X POST \
    --data "{\"content\": \"$content\", \"parent_id\": \"$parent\"}" \
    -H "Content-Type: application/json" \
    -H "X-Request-Id: $(uuidgen)" \
    -H "Authorization: Bearer $TODOIST_TOKEN" >/dev/null
