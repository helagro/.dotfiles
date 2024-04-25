source "$HOME/.dotfiles/.zshrc/shared.sh"

if [ -f "$HOME/.dotfiles/.zshrc/secrets.sh" ]; then
    source "$HOME/.dotfiles/.zshrc/secrets.sh"
fi

if [ "$(uname)" = "Darwin" ]; then
    source "$HOME/.dotfiles/.zshrc/macOS.sh"
elif [ "$(uname)" = "Linux" ]; then
    source "$HOME/.dotfiles/.zshrc/"
fi
