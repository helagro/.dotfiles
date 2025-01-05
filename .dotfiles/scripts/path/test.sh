echo "$1"
echo "$1" | awk -v today="$(date +%Y-%m-%d)" '
{
    for (i=1; i<=NF; i++) {
        if (substr($i, 1, 3) == "ES-" && substr($i, 4) < today) {
            exit 1;
        }
    }
}'
