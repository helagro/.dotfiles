#!/bin/zsh

# ========================= FUNCTIONS ======================== #

ask() {
    echo -n "$1 (y/n) "
    read response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ========================= COMMANDS ========================= #

sudo journalctl --vacuum-size=50M
chsh -s $(which zsh)

if ask "Setup login hook?"; then
    mkdir -p ~/.config/systemd/user
    su -c "
        cp -f $HOME/.dotfiles/setup/linux/dotfiles.service /etc/systemd/system/dotfiles.service && \
        sudo systemctl daemon-reload && \
        sudo systemctl enable dotfiles.service && \
        sudo systemctl start dotfiles.service"
fi

# install ---------------------------------------------------- #
if ask "Install programs?"; then

    if command -v apt; then
        sudo apt update
        sudo apt upgrade
    elif command -v brew; then
        brew update
        brew upgrade
    else
        echo "No valid package manager found for updating"
    fi

    if ask "Install brew?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ask "Install bat?"; then
        if command -v apt &>/dev/null; then
            sudo apt install bat
        elif command -v brew &>/dev/null; then
            brew install bat
        else
            echo "No valid package manager found"
        fi
    fi

fi
