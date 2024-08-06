# ------------------------- VARIABLES ------------------------ #

doc="$HOME/Documents"
dev="$HOME/Developer"
vault="$HOME/Dropbox/vault"
DISABLE_AUTO_UPDATE="true"

export DISABLED_TD_APP_ITEMS="" # Items must end with a comma, even last one
export GPG_TTY=$(tty)
export PATH="$HOME/.dotfiles/scripts/path:$PATH"

# ------------------------- UNCATEGORISED ALIASES ------------------------ #

alias src="source $HOME/.zshrc"
alias c="bc -le"

alias gpt="aichat"
alias gpt4="aichat -m openai:gpt-4"

# ------------------ UNCATEGORISED FUNCTIONS ----------------- #

function tl {
    ext="${1##*.}"
    [[ "$1" != *.* ]] && ext="json"

    url="https://helagro.se/tools/$1"
    content=$(curl -s "$url" -b "id=u3o8hiefo" -b "a75h=$A75H")

    if command -v bat &>/dev/null; then
        echo "$content" | bat -pPl "$ext"
    else
        echo "$content"
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

function cnt {
    if [[ -e "$HOME/.dotfiles/data/cnt.txt" ]]; then
        cnt=$(cat "$HOME/.dotfiles/data/cnt.txt")
    else
        cnt=0
    fi

    echo $cnt
    echo -n $((cnt + 1)) >"$HOME/.dotfiles/data/cnt.txt"
}

# ---------------------------- GIT --------------------------- #

alias gaa="git add ."                    # Git Add All
alias gcm="git commit -m "               # Git Commit Message
alias gsw="git switch "                  # Git Switch
alias gcu="git commit --amend --no-edit" # Git Commit Update

function gclone { git clone "git@github.com:helagro/$1.git" $dev/$1; }
function gi() { curl -s https://www.toptal.com/developers/gitignore/api/$@; }
function yq() { yadm add -u && yadm commit -m "$*" && yadm push; }

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
        (nohup a.sh "$*" >>$HOME/.dotfiles/data/a.log 2>&1 &)
    fi
}

function m_vared {
    line=""
    vared -p "%B%F{red}-%f%b " line
}

# ------------------------- OBSIDIAN ------------------------- #

function do_now {
    if ob "$*" | a; then
        echo -n >"$vault/$*.md"
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
    file=$(find "$vault/i" -type f | sort -R | head -n 1)
    bat -P "$file"

    a ob
}
