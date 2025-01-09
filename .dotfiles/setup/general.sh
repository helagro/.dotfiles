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
conda env create -f $HOME/.dotfiles/config/environment.yml

# ----------------------- ADDS OH MY ZSH ---------------------- #

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    (
        export CHSH=no KEEP_ZSHRC=yes
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        exit
    )

    echo "Waiting for Oh My Zsh to install..."
fi

rm -rf $HOME/.oh-my-zsh/custom/*
cp -r $HOME/.dotfiles/config/ohmyzsh/* $HOME/.oh-my-zsh/custom/

addIfMissing 'export ZSH="$HOME/.oh-my-zsh"'
addIfMissing 'source "$ZSH/oh-my-zsh.sh"'

# ----------------- ADDS MY ZSH CONFIGURATION ----------------- #

addIfMissing 'source "$HOME/.dotfiles/.zshrc/router.sh"'

exec zsh
