# NOTE - returns 1 if should stop sourcing

# -------------------------- ALIASES ------------------------- #

alias is_dark='[[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]'
alias tod="date +'%Y-%m-%d'"
alias gpt4="aichat -s -m openai:gpt-4o"

# ---------------------------- ZSH --------------------------- #

autoload -Uz compinit
compinit

setopt HIST_IGNORE_ALL_DUPS # Remove old duplicate commands from history
setopt HIST_IGNORE_DUPS     # Remove new duplicate commands from history
setopt HIST_IGNORE_SPACE    # Remove commands starting with space from history, useful for secrets

zstyle ':omz:update' mode auto

HISTSIZE=100000
SAVEHIST=20000

# --------------------------- MAIN --------------------------- #

function rand_elem {
    local arr="$1"
    echo ${arr[RANDOM % $#arr + 1]}
}
