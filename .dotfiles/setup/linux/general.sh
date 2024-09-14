chsh -s $(which zsh)
mkdir -p ~/.config/systemd/user

su -c "
cp -f $HOME/.dotfiles/setup/linux/dotfiles.service /etc/systemd/system/dotfiles.service && \
sudo systemctl daemon-reload && \
sudo systemctl enable dotfiles.service && \
sudo systemctl start dotfiles.service
"
