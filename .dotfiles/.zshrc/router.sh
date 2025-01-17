#!/bin/zsh

if ! source "$HOME/.dotfiles/.zshrc/first.sh"; then
    return 0
fi

if [ -f "$HOME/.dotfiles/.zshrc/secrets.sh" ]; then
    source "$HOME/.dotfiles/.zshrc/secrets.sh"
fi

if [ -f "$HOME/.dotfiles/.zshrc/custom.sh" ]; then
    source "$HOME/.dotfiles/.zshrc/custom.sh"
fi

if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/hotkey"* ]]; then
    if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/hotkey/note" ]]; then
        vim $HOME/Desktop/1.md
    fi

    return 0
fi

source "$HOME/.dotfiles/.zshrc/shared.sh"

if [ "$(uname)" = "Darwin" ]; then
    source "$HOME/.dotfiles/.zshrc/macOS.sh"
elif [ "$(uname)" = "Linux" ]; then
    source "$HOME/.dotfiles/.zshrc/linux.sh"
fi

if command -v brew >/dev/null 2>&1 && [ -f $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]; then
    source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
fi

# --------------------------- LAST --------------------------- #

if [[ -n "$ZSH_HIGHLIGHT_STYLES" ]]; then
    ZSH_HIGHLIGHT_STYLES+=(
        single-hyphen-option 'fg=red'
        double-hyphen-option 'fg=red'
    )
fi
