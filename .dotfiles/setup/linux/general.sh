#!/bin/zsh

# ------------------------- FUNCTIONS ------------------------ #

ask() {
    echo -n "$1 (y/n) "
    read response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ------------------------- COMMANDS ------------------------- #

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
