#!/bin/zsh

cd $HOME
yadm -C $HOME/.dotfiles remote set-url origin git@github.com:helagro/.dotfiles.git

function addIfMissing {
    grep -qF "$1" "$HOME/.zshrc" || echo "$1" >>"$HOME/.zshrc"
}

# ----------------- ADD MY ZSH CONFIGURATION ----------------- #

addIfMissing 'source "$HOME/.dotfiles/.zshrc/router.sh"'

# ----------------------- ADD OH MY ZSH ---------------------- #

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone https://github.com/helagro/ohmyzsh.git $HOME/.oh-my-zsh
    git -C $HOME/.oh-my-zsh remote set-url origin git@github.com:helagro/ohmyzsh.git
fi

addIfMissing 'export ZSH="$HOME/.oh-my-zsh"'
addIfMissing 'source "$ZSH/oh-my-zsh.sh"'
