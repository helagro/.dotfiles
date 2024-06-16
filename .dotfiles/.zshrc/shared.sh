export PATH=".dotfiles/scripts/path:$PATH"
export SETTINGS_FILE=settings/mac.json
export GPG_TTY=$(tty)

# ------------------------- UNCATEGORISED ALIASES ------------------------ #

alias src="source $HOME/.zshrc"
alias talk="curl 'https://system.easypractice.net/online_booking/getAvailableTimesInMonth' -H 'Content-Type: application/json' --data-raw '{\"calendar_id\":605522,\"permalink\":\"varga-psykoterapi\",\"product_ids\":[186358],\"year\":2023,\"month\":12}'"

alias gpt="aichat"
alias gpt4="aichat -m openai:gpt-4"

# ------------------ UNCATEGORISED FUNCTIONS ----------------- #

function tl {
    ext="${1##*.}"
    [[ "$1" != *.* ]] && ext="json"

    url="https://helagro.se/tools/$1"
    curl -s $url -b "id=u3o8hiefo" -b "a75h=$A75H" | bat -pPl $ext
}

function ob {
    bat -P "$vault/i/$*.md" 2>/dev/null
    bat -P "$vault/p/$*.md" 2>/dev/null
    bat -P "$vault/tmp/$*.md" 2>/dev/null
    bat -P "$vault/_/log/$*.md" 2>/dev/null
}

function clr {
    cols=$(tput cols)
    for ((i = 0; i < $cols; i++)); do
        echo -n "="
    done

    echo "\n"
    clear
}

# ---------------------------- GIT --------------------------- #

alias yq="yadm add -u && yadm commit -m 'Unspecified' && yadm push"
alias gaa="git add ."                    # Git Add All
alias gcm="git commit -m "               # Git Commit Message
alias gsw="git switch "                  # Git Switch
alias gcu="git commit --amend --no-edit" # Git Commit Update

function gclone { git clone "git@github.com:helagro/$1.git" $dev/$1; }
function gi() { curl -s https://www.toptal.com/developers/gitignore/api/$@; }

# Git Quick Local
function gql {
    commit_message="$*"
    if [ -z "$commit_message" ]; then
        commit_message="Unspecified"
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
    url=$(git config --get remote.origin.url)
    url=$(echo $url | sed 's/git@github.com:/https:\/\/github.com\//g')
    open $url
}

# -------------------------- TODOIST ------------------------- #

alias td="todoist"
alias tdi='td s && tdl "(tod | od | p1)"'
alias tdls='td s && tdl'
alias tdl="tdl.sh"

function tdc {
    for arg in "$@"; do
        (nohup todoist c "$arg" >/dev/null 2>&1 &)
    done
}

function a {
    if [ -z "$*" ]; then
        m_vared

        while [[ $line != 'q' ]]; do
            line=$(echo "$line" | tr -d '\\')
            a "$line"
            m_vared
        done
    else
        echo "$line" >>$HOME/.dotfiles/data/a.log
        (nohup a.sh "$*" >>$HOME/.dotfiles/data/a.log 2>&1 &)
    fi
}

function m_vared {
    line=""
    vared -p "%B%F{red}-%f%b " line
}
