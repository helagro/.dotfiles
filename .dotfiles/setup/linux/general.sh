#!/bin/zsh

# ------------------------- FUNCTIONS ------------------------ #

ask() {
    echo -n "$1 (y/n) "
    read response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ------------------------- COMMANDS ------------------------- #

chsh -s $(which zsh)
mkdir -p ~/.config/systemd/user

if ask "Setup login hook?"; then
    su -c "
        cp -f $HOME/.dotfiles/setup/linux/dotfiles.service /etc/systemd/system/dotfiles.service && \
        sudo systemctl daemon-reload && \
        sudo systemctl enable dotfiles.service && \
        sudo systemctl start dotfiles.service"
fi
