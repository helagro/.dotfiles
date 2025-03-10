#!/bin/zsh

# =========================== SETUP ========================== #

ZSH_HIGHLIGHT_REGEXP+=(
    '#[a-z0-9]+[a-zA-Z0-9]*' fg=green,bold
    '(\s|^)p3(\s|$)' fg=magenta,underline
    '(\s|^)p1(\s|$)' fg=red,bold
    '\*\*.+\*\*' fg=red,bold
    '(?<!\*)\*[^*]+\*(?!\*)' fg=magenta,underline
    ';' fg=yellow,bold
    '@\w+' fg=blue
    '\$\([^\$]+\)' fg=cyan
)

unset ZSH_AUTOSUGGEST_STRATEGY
unset HISTFILE SAVEHIST

# ========================= FUNCTIONS ======================== #

function on_tab {
    clr
    a
}
