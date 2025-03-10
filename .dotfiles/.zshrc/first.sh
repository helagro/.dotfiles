# NOTE - returns 1 if should stop sourcing

# -------------------------- ALIASES ------------------------- #

alias gpt4="aichat -s -m openai:gpt-4o"
alias gpt3="aichat -s -m openai:gpt-3.5-turbo"
alias is_dark='[[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]'
alias tod="date +'%Y-%m-%d'"

# ---------------------------- ZSH --------------------------- #

autoload -Uz compinit
compinit

setopt HIST_IGNORE_ALL_DUPS # Remove old duplicate commands from history
setopt HIST_IGNORE_DUPS     # Remove new duplicate commands from history
setopt HIST_IGNORE_SPACE    # Remove commands starting with space from history, useful for secrets

zstyle ':omz:update' mode auto

# --------------------------- MAIN --------------------------- #

function rand_elem {
    local arr="$1"
    echo ${arr[RANDOM % $#arr + 1]}
}
