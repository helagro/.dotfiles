function m_find {
    find $1 -not \( -path "*node_modules*" -prune -o -path "*_ARCHIVE*" -prune \) -ipath "$2" 2>/dev/null
}

a1=$(echo "$1" | tr '[:upper:]' '[:lower:]')

if [[ $a1 == "docs" || $a1 == "doc" || $a1 == "documents" ]]; then
    m_find ~/Documents "$2"
elif [[ $a1 == "desk" || $a1 == "desktop" ]]; then
    m_find ~/Desktop "$2"
elif [[ $a1 == "down" || $a1 == "downloads" ]]; then
    m_find ~/Downloads "$2"
elif [[ $a1 == "obs" || $a1 == "vault" || $a1 == "obsidian " ]]; then
    m_find ~/obsidian "$2"
elif [[ $a1 == "cloud" ]]; then
    m_find /Users/h/Library/Mobile\ Documents/com~apple~CloudDocs/ "$2"
else
    m_find ~/Downloads "$a1"
    m_find ~/Desktop "$a1"
    m_find ~/Documents "$a1"
    m_find ~/Pictures "$a1"
    m_find ~/obsidian "$a1"
    m_find /Users/h/Library/Mobile\ Documents/com~apple~CloudDocs/ "$2"
fi
