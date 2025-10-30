do_newline=true
if [[ $1 == "-N" ]]; then
    do_newline=false
    shift
fi

url="$TOOLS_URL/$1"
content=$(curl -H "Authorization: Bearer $A75H" -s "$url" -b "id=u3o8hiefo")
return_code=$?

if [ "$return_code" -ne 0 ]; then
    exit "$return_code"
fi

printf "$content" | rat.sh -pPl "json"
$do_newline && echo || :