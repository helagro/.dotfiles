# ------------------------- OTHER ------------------------ #

export PATH="/Users/h/Library/Python/3.9/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=$PATH:$HOME/go/bin

if command -v rbenv &>/dev/null; then
    eval "$(rbenv init -)"
fi

# -------------------------- SOURCE -------------------------- #

if [[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# ----------------------- OTHER ALIASES ---------------------- #

alias vi="nvim"
alias archive="$HOME/Documents/archiver-go/build/macOS"
alias breake="nvim $doc/break-timer/.env"
alias wifi="networksetup -setairportpower en0" # NOTE - on/off

# ------------------------- OTHER FUNCTIONS ------------------------ #

function theme {
    local new_mode=$1

    if [ -z "$new_mode" ]; then
        new_mode='not dark mode'
    fi

    osascript -e "
        tell application \"System Events\"
            tell appearance preferences
                set dark mode to $new_mode
            end tell
        end tell
    "
}

function on_tab {
    local role=$(basename $(pwd))
    clr

    if [[ $role == "a" ]]; then
        a
    elif [[ $role == "ai" ]]; then
        gpt4
    fi

}

function talk {
    local text
    read -r -d '' text

    local chunk_size=4500
    local text_length=${#text}
    local start=1
    local files=()
    local file_name=""

    while ((start <= text_length)); do
        local chunk="${text[start - 1, start + chunk_size - 2]}"

        file_name="$HOME/Desktop/$(cnt | tr -d '[:space:]').mp3"
        echo "$chunk" | gosling - $file_name -r 1.2
        files+=("$file_name")
        ((start += chunk_size))
    done

    file_name="$HOME/Desktop/$(cnt | tr -d '[:space:]').mp3"
    cat "${files[@]}" >"$file_name"
    open $file_name
    rm "${files[@]}"
}

function pass {
    local passw=$(op item get "$@" --reveal --fields password)
    echo $passw
    echo $passw | pbcopy
}

function e {
    if [ -d "$dev/$1" ]; then
        code "$dev/$1"
    elif [ -d "$doc/$1" ]; then
        code "$doc/$1"
    elif [ -d "$1" ]; then
        code "$1"
    elif [ -e "$vault/$*.md" ]; then
        nvim "$vault/$*.md"
        return 0
    elif [ -e "$*" ]; then
        nvim "$*"
        return 0
    else
        gclone $1

        if [ $? -eq 0 ]; then
            code "$dev/$1"
        else
            return 1
        fi
    fi

    if [ $# -ge 2 ]; then
        shift
        e $*
    fi
}

# ---------------------- APPLE SHORTCUTS --------------------- #

function short {
    echo "$2" | shortcuts run "$1"

    if [[ $? -ne 0 ]]; then
        echo "Failure when running: $1 $2"
        return 1
    fi
}

function inv {
    if [[ $1 == "1" ]]; then
        1="on"
    fi

    short invert $1
}

function day {
    local clipBoard=$(pbpaste)

    short day "$1"
    pbpaste

    echo && echo
    echo -n $clipBoard | pbcopy

    tdis
}

# -------------------------- ROUTINE ------------------------- #

function dawn {
    local focus_mode=$1

    if [ -z "$focus_mode" ]; then
        focus_mode="off"
    fi

    short focus "$focus_mode"
    short night_shift 0
    short focus
    theme 0
    wifi on

    a dawn
    day tod
    ob dawn

    tl streaks
    ob p

    later
}

function eve {
    a eve
    day tom
    echo

    echo temp: $(sens temp 2>&1)
    echo "podd: $(is podd 1)"
    echo "tv_min: $(is tv_min 1)"

    tl hb
    echo

    echo
    ob eve

    short focus sleep
    short night_shift 1
    theme 1

    a "p_ett $(tdis | lines | tr -d '[:space:]') s"
}

function bedtime {
    wifi off
    ob bedtime
}

# -------------------------- TIMING -------------------------- #

alias timer="short timer"

function medd {
    short focus on
    sw $1 "medd"
    short focus off
}

function sw {
    local start_time=$(date +%s)

    caffeinate -disu -i $doc/stopwatch/main "$1"

    if [ $? -ne 2 ]; then
        asciiquarium
    fi

    local end_time=$(date +%s)
    local min=$((($end_time - $start_time) / 60))

    if [ -n "$2" ] && [ "$min" -ne 0 ]; then
        a "$2 $min"
    fi
}
