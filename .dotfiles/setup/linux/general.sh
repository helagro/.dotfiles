mkdir -p ~/.config/systemd/user
cp -f $HOME/.dotfiles/setup/linux/dotfiles.service /etc/systemd/system/dotfiles.service

su -c "sudo systemctl daemon-reload && sudo systemctl enable dotfiles.service && sudo systemctl start dotfiles.service"
