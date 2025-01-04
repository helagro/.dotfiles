vault="$HOME/vaudlt"
(! command -v ob.sh >/dev/null 2>&1 || [ ! -e "$vault" ]) && exit 1

echo fine
