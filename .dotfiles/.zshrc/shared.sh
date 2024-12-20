# ------------------------- VARIABLES ------------------------ #

doc="$HOME/Documents"
dev="$HOME/Developer"
vault="$HOME/vault"
DISABLE_AUTO_UPDATE="true"

export DISABLED_TD_APP_ITEMS="---,ob," # Items must end with a comma, even last one
export GPG_TTY=$(tty)
export PATH="$HOME/.dotfiles/scripts/path:$PATH"

# ------------------------- UNCATEGORISED ALIASES ------------------------ #

alias c="qalc"
alias lines="grep -v '^$' | wc -l"
alias gpt4="aichat -s -m openai:gpt-4o"

alias hm="python3 $HOME/.dotfiles/scripts/hm.py | bat -pPl 'json'"
alias st="python3 $HOME/.dotfiles/scripts/st.py"

# ------------------ UNCATEGORISED FUNCTIONS ----------------- #

if ! command -v bat >/dev/null 2>&1; then
    function bat { cat; }
fi

function rand { echo $((1 + RANDOM % ($1))); }

function tl {
    local url="https://helagro.se/tools/$1"
    local content=$(curl -s "$url" -b "id=u3o8hiefo" -b "a75h=$A75H")

    # If bat is installed
    if command -v bat &>/dev/null; then
        echo "$content" | bat -pPl "json"

    # If bat is not installed
    else
        echo "$content"
    fi
}

function clr {
    local cols=$(tput cols)
    for ((i = 0; i < $cols; i++)); do
        echo -n "="
    done

    echo "\n"
    clear
}

# Counter function, used by other things
function cnt {
    if [[ -e "$HOME/.dotfiles/tmp/cnt.txt" ]]; then
        local cnt=$(cat "$HOME/.dotfiles/tmp/cnt.txt")
    else
        local cnt=0
    fi

    echo $cnt
    echo -n $((cnt + 1)) >"$HOME/.dotfiles/tmp/cnt.txt"
}

# ---------------------------- GIT --------------------------- #

alias gaa="git add ."      # Git Add All
alias gcm="git commit -m " # Git Commit Message
alias gsw="git switch "    # Git Switch

function gclone { git clone "git@github.com:helagro/$1.git" $dev/$1; }
function gi { curl -s https://www.toptal.com/developers/gitignore/api/$@; }
function yq { yadm add -u && yadm commit -m "$*" && yadm push; }

# Git Quick Local
function gql {
    local commit_message="$*"
    if [ -z "$commit_message" ]; then
        local commit_message="Unspecified"
    fi

    git add .
    git commit -m "$commit_message"
}

# Git Quick
function gq {
    gql "$*"
    git push
}

# Git Delete Branch
function gdb {
    git branch -d "$1"
    git push origin --delete "$1"
}

function repo {
    local url=$(git config --get remote.origin.url)
    local url=$(echo $url | sed 's/git@github.com:/https:\/\/github.com\//g')
    open $url
}

# ------------------------- TRACKING ------------------------- #

function csv { conda run -n main python3 "$HOME/.dotfiles/scripts/jsons_to_csv.py" $@ | bat -pPl 'tsv'; }

function sens { curl -sS "192.168.3.46:8004/$1" | bat -pPl "json"; }

function slope {
    local m="${1:-7}"

    tac | awk -v m="$m" '{
        y[NR]=$2;
        x[NR]=NR
    }
    END {
        n=NR;
        sumx=sumy=sumxy=sumxx=0;
        for (i=1;i<=n;i++) {
        sumx+=x[i];
        sumy+=y[i];
        sumxy+=x[i]*y[i];
        sumxx+=x[i]*x[i]
        }
        slope=(n*sumxy-sumx*sumy)/(n*sumxx-sumx^2);
        print slope * m
    }'
}

function is {
    if [ $# -gt 0 ]; then
        is_output=$(conda run -n main python3 "$HOME/.dotfiles/scripts/exist.py" $@)
    fi

    echo $is_output | bat -pPl 'json'
}

# -------------------------- TODOIST ------------------------- #

alias td="todoist"
alias tdl="tdl.sh"
alias tdi="tdl '(tod | od | p1)'"

alias tdis='td s && tdi'
alias tdls='td s && tdl'

function tdu {
    local id=$1
    shift
    local update="$@"

    local content_line=$(td show $id | grep Content | cut -d' ' -f2-)

    a "$content_line" "$update"
    tdc $id
}

function tdc {
    for arg in "$@"; do
        (nohup todoist c "$arg" >/dev/null 2>&1 &)
    done
}

function a {
    # If no arguments passed
    if [ -z "$*" ]; then

        # If terminal
        if [ -t 0 ]; then
            m_vared

            # Ask for lines until 'q' is entered
            while [[ $line != 'q' ]]; do
                line=$(echo "$line" | tr -d '\\')
                a "$line"
                m_vared
            done

        # If piped
        else

            # Read lines from pipe
            while read -r line; do
                line=$(echo "$line" | sed -e 's/^- \[ \] //' -e 's/^- //') # Remove checkboxes
                a "$line"
            done
        fi

    # If arguments passed
    else
        (nohup a.sh "$*" >>$HOME/.dotfiles/logs/a.log 2>&1 &)
    fi
}

function m_vared {
    line=""
    vared -p "%B%F{red}-%f%b " line
}

# ------------------------- OBSIDIAN ------------------------- #

alias randine="grep -v '^$' | shuf -n 1"

function do_now {
    local file_name="$vault/$*.md"

    if [[ ! -e "$file_name" ]]; then
        echo "$file_name does not exist"
        return 1
    fi

    local content=$(cat "$file_name")
    if echo $content | awk '/---/ {found = NR; next} NR > found' | a; then
        echo $content | tac | awk '/---/ {found = 1; next} found' >"$file_name"
        echo "---" >>"$file_name"
    fi
}

function ob {
    bat -P "$vault/i/$*.md" 2>/dev/null
    bat -P "$vault/p/$*.md" 2>/dev/null
    bat -P "$vault/tmp/$*.md" 2>/dev/null
    bat -P "$vault/_/log/$*.md" 2>/dev/null
    bat -P "$vault/$*.md" 2>/dev/null

    a ob
}

function randote {
    local file=$(find "$vault/i" -type f | sort -R | head -n 1)
    bat -P "$file"

    a ob
}
