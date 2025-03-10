#!/bin/zsh

function on_tab {
    local role=$(basename $(pwd))

    if is_dark; then
        export AICHAT_LIGHT_THEME=0
    else
        export AICHAT_LIGHT_THEME=1
    fi

    if [[ $role == "ai" ]]; then
        gpt4
    elif [[ $role == "ai_cheap" ]]; then
        gpt3
    else
        echo "Unknown role: $role"
    fi
}
