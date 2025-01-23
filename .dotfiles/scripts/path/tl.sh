url="$TOOLS_URL/$1"
content=$(curl -H "Authorization: Bearer $A75H" -s "$url" -b "id=u3o8hiefo")
return_code=$?

if [ "$return_code" -ne 0 ]; then
    exit "$return_code"
fi

# If bat is installed
if command -v bat &>/dev/null; then
    echo "$content" | bat -pPl "json"

# If bat is not installed
else
    echo "$content"
fi
