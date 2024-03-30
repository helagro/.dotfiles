#!/bin/zsh

cd $HOME

function addIfMissing {
    grep -qF "$1" "$HOME/.zshrc" || echo "$1" >>"$HOME/.zshrc"
}

# ----------------- ADD MY ZSH CONFIGURATION ----------------- #

addIfMissing 'source "$HOME/.dotfiles/.zshrc/router.sh"'

# ----------------------- ADD OH MY ZSH ---------------------- #

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone git@github.com:helagro/ohmyzsh.git $HOME/.oh-my-zsh
fi

addIfMissing 'export ZSH="$HOME/.oh-my-zsh"'
addIfMissing 'source "$ZSH/oh-my-zsh.sh"'
