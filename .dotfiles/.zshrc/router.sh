#!/bin/zsh

source "$HOME/.dotfiles/.zshrc/first.sh"

# ========================== SECRETS ========================= #

if ls "$HOME/.dotfiles/.zshrc/secret/" | grep ".sh" >/dev/null; then
    for file in "$HOME/.dotfiles/.zshrc/secret/"*.sh; do
        [ -f "$file" ] && source "$file"
    done
fi

# ========================== SPECIAL WINDOWS ========================== #

if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/ai"* ]]; then
    source "$HOME/.dotfiles/.zshrc/special/ai.sh"
    return 0
fi

if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/hotkey"* ]]; then
    source "$HOME/.dotfiles/.zshrc/special/hotkey.sh"

    if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/hotkey/note" ]]; then
        vim $HOME/Desktop/1.md
    fi

    return 0
fi

# =================================== OTHER ================================== #

export PATH="$HOME/.dotfiles/scripts/path:$(printf "%s:" "$HOME/.dotfiles/scripts/path"/*/):$PATH"

source "$HOME/.dotfiles/.zshrc/special/act.sh"
if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/act" ]]; then
    return 0
fi

# ========================== SHARED ========================== #

source "$HOME/.dotfiles/.zshrc/main.sh"

# ===================== PLATFORM SPECIFIC ==================== #

if [ "$(uname)" = "Darwin" ]; then

    if [[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
        source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi
    if [[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi

    source "$HOME/.dotfiles/.zshrc/platforms/macOS.sh"

    if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/a" ]]; then
        source "$HOME/.dotfiles/.zshrc/special/a.sh"
    else
        source "$HOME/.dotfiles/.zshrc/routine.sh"
    fi

elif [ "$(uname)" = "Linux" ]; then
    source "$HOME/.dotfiles/.zshrc/platforms/linux.sh"
fi

# ========================== PLUGINS ========================= #

if command -v brew >/dev/null 2>&1 && [ -f $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]; then
    source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
fi

# =========================== LAST =========================== #

if [[ -n "$ZSH_HIGHLIGHT_STYLES" ]]; then
    ZSH_HIGHLIGHT_STYLES+=(
        single-hyphen-option 'fg=red'
        double-hyphen-option 'fg=red'
    )
fi
