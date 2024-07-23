#!/bin/zsh

source $HOME/.dotfiles/.zshrc/secrets.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

cd $HOME
python3 dropbox.py start

# echo "Starting services..."
# pm2 start online-tools resume todoist-app

echo "Done!"
