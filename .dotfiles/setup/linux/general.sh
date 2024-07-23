mkdir -p ~/.config/systemd/user
cp -f $HOME/.dotfiles/setup/linux/dotfiles.service $HOME/.config/systemd/user/dotfiles.service

systemctl --user daemon-reload
systemctl --user enable dotfiles.service
systemctl --user start dotfiles.service
