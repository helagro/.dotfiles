# Move under

curl -sS https://api.todoist.com/sync/v9/sync \
    -H "Authorization: Bearer $TODOIST_TOKEN" \
    -d commands="[
    {
        \"type\": \"item_move\",
        \"uuid\": \"$(uuidgen)\",
        \"args\": {
            \"id\": \"$2\", 
            \"parent_id\": \"$1\"
        }
    }]" >/dev/null
