export PATH=".dotfiles/scripts/path:$PATH"

alias src="source $HOME/.zshrc"
alias talk="curl 'https://system.easypractice.net/online_booking/getAvailableTimesInMonth' -H 'Content-Type: application/json' --data-raw '{\"calendar_id\":605522,\"permalink\":\"varga-psykoterapi\",\"product_ids\":[186358],\"year\":2023,\"month\":12}'"
alias me="tl is.json && echo && tl hb"

alias gpt="aichat"
alias gpt4="aichat -m openai:gpt-4"

function tl {
    if [ -e "$vault/$*.md" ]; then
        bat -P "$vault/$*.md"
    else
        a75h=uyE1bf9kt60kYj

        ext="${1##*.}"
        [[ "$1" != *.* ]] && ext="json"

        url="https://helagro.se/tools/$1"
        curl -b "a75h=$a75h" -s $url | bat -pPl $ext
    fi
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

alias gaa="git add ."                    # Git Add All
alias gcm="git commit -m "               # Git Commit Message
alias gsw="git switch "                  # Git Switch
alias gcu="git commit --amend --no-edit" # Git Commit Update

function gclone { git clone "https://github.com/helagro/$1.git" $dev/$1; }
function gi() { curl -s https://www.toptal.com/developers/gitignore/api/$@; }

# Git Quick Local
function gql {
    commit_message="$*"
    if [ -z "$commit_message" ]; then
        commit_message="unspecified"
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

function tdl {
    # isZt
    # ztRes="$?"
    tdl.sh 1 "$*"
}

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
        echo "a - $line" >>$HOME/.dotfiles/data/td.log
        (nohup a.sh "$*" >>$HOME/.dotfiles/data/td.log 2>&1 &)
    fi
}

function m_vared {
    line=""
    vared -p "%B%F{red}-%f%b " line
}
