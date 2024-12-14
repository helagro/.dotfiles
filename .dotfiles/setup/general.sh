#!/bin/zsh

function addIfMissing {
    grep -qF "$1" "$HOME/.zshrc" || echo "$1" >>"$HOME/.zshrc"
}

# ------------------------- UNCATEGORISED COMMANDS ------------------------- #

cd $HOME

git config --global core.excludesFile "$HOME/.gitignore"
yadm -C $HOME/.dotfiles remote set-url origin git@github.com:helagro/.dotfiles.git
mkdir -p Developer
zstyle ':omz:update' mode disabled
conda env create -f $HOME/.dotfiles/environment.yml

# ----------------- ADDS MY ZSH CONFIGURATION ----------------- #

addIfMissing 'source "$HOME/.dotfiles/.zshrc/router.sh"'

# ----------------------- ADDS OH MY ZSH ---------------------- #

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone https://github.com/helagro/ohmyzsh.git $HOME/.oh-my-zsh
    git -C $HOME/.oh-my-zsh remote set-url origin git@github.com:helagro/ohmyzsh.git
fi

addIfMissing 'export ZSH="$HOME/.oh-my-zsh"'
addIfMissing 'source "$ZSH/oh-my-zsh.sh"'
