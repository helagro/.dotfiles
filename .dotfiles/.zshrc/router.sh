#!/bin/zsh

[[ "$PWD" == "$HOME/.dotfiles/config/tabs/"* ]] && is_special_tab=true || is_special_tab=false
$is_special_tab && [[ "$PWD" == "$HOME/.dotfiles/config/tabs/work" ]] && is_work_tab=true || is_work_tab=false
$is_special_tab && [[ "$PWD" == "$HOME/.dotfiles/config/tabs/red" ]] && export is_red_tab=true || export is_red_tab=false

source "$HOME/.dotfiles/.zshrc/first.sh"
export PATH="$HOME/.dotfiles/scripts/path:$(printf "%s:" "$HOME/.dotfiles/scripts/path"/*/):$PATH"

# ========================== SECRETS ========================= #

if ls "$HOME/.dotfiles/.zshrc/secret" | grep ".sh" >/dev/null; then
    for file in "$HOME/.dotfiles/.zshrc/secret/always_sourced/"*.sh; do
        [ -f "$file" ] && source "$file"
    done
fi

# ========================== SIMPLE SPECIAL WINDOWS ========================== #

if $is_special_tab; then
    if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/ai"* ]]; then
        source "$HOME/.dotfiles/.zshrc/special/ai.sh"
        return 0
    fi

    if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/hotkey"* ]]; then
        source "$HOME/.dotfiles/.zshrc/secret/sys.sh"
        source "$HOME/.dotfiles/.zshrc/secret/hotkey.sh"
        source "$HOME/.dotfiles/.zshrc/special/hotkey.sh"

        if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/hotkey/note" ]]; then
            vim $HOME/Desktop/1.md
        fi

        return 0
    fi
fi

# =================================== GENERAL ================================== #

source "$HOME/.dotfiles/.zshrc/main.sh"

# ================================ ALTERED TABS ================================ #

if $is_red_tab; then
    printf "\033]10;rgb:ff/30/30\007"
    cd "$HOME"
else
    red_mode 0 0
fi

if $is_work_tab; then
    cd "$HOME"
else
    source "$HOME/.dotfiles/.zshrc/secret/state.sh"
    source "$HOME/.dotfiles/.zshrc/secret/sys.sh"
    source "$HOME/.dotfiles/.zshrc/sys.sh"
fi

# ===================== PLATFORM SPECIFIC ==================== #

if [ "$(uname)" = "Darwin" ]; then

    if [[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi

    if ! $is_red_tab && [[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
        source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi

    source "$HOME/.dotfiles/.zshrc/platforms/macOS.sh"

elif [ "$(uname)" = "Linux" ]; then
    source "$HOME/.dotfiles/.zshrc/platforms/linux.sh"
    source "$HOME/.dotfiles/.zshrc/secret/linux.sh"
fi

# ========================== COMPLEX SPECIAL TABS ========================= #

if $is_special_tab; then
    if [[ "$PWD" == "$HOME/.dotfiles/config/tabs/act" ]]; then
        source "$HOME/.dotfiles/.zshrc/special/acts.sh"
    elif [[ "$PWD" == "$HOME/.dotfiles/config/tabs/a" ]]; then
        source "$HOME/.dotfiles/.zshrc/secret/a.sh"
        source "$HOME/.dotfiles/.zshrc/special/a_custom.sh"
        source "$HOME/.dotfiles/.zshrc/special/a.sh"
    fi
fi

if ! $is_work_tab && [[ -e "$HOME/.dotfiles/.zshrc/routine.sh" ]]; then
    source "$HOME/.dotfiles/.zshrc/routine.sh"
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
